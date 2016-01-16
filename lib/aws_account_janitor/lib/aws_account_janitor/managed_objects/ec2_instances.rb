module AwsAccountJanitor
  class ManagedObjects
    class EC2Instances < Abstract
      REQUIRED_TAGS = ["Owner", "Project"]

      def orphaned
        {
          ec2_abandoned_instances: all { |i| is_orphaned?(i) }
        }
      end

      private

      def ec2
        @ec2 ||= Aws::EC2::Client.new
      end

      def all
        instance_filter = [
          { name: "instance-state-name" , values: ["running"] }
        ]

        next_token = nil
        data = []

        loop do
          instances = ec2.describe_instances(filters: instance_filter, max_results: 100, next_token: next_token)
          data += instances
            .reservations
            .collect { |r| r.instances.select { |i| yield i } }
            .compact
            .flatten
            .collect(&:to_h)
            .each { |i| standardize(i) }
          next_token = instances.next_token
          break unless next_token
        end

        data
      end

      def is_orphaned?(i)
        @threshold ||= Time.new.ago(7)

        i.launch_time < @threshold &&
        ( !tag_exists?(i, 'Owner') || !tag_exists?(i, 'Project') )
      end

      def standardize(i)
        i["daily_cost"] = instance_price(i[:instance_type]) * 24
        i["create_time"] = i["launch_time"]
      end

      def linux_prices(region)
        return @linux_prices if @linux_prices
        @linux_prices =
          JSON.parse(
            URI('https://a0.awsstatic.com/pricing/1/ec2/linux-od.min.js?callback=callback&_=1445012489295')
            .open
            .read
            .gsub(/^[^{]+/, '')
            .gsub(/[^}]+$/, '')
            .gsub(/([\w]+):/, '"\1":')
          )
        @linux_prices = @linux_prices["config"]["regions"].detect { |r| r["region"] == region }
      end

      def instance_price(instance_type)
        @prices = {}
        return @prices[instance_type] if @prices[instance_type]
        linux_prices(Aws.config[:region])["instanceTypes"].each do |g|
          g["sizes"].each do |s|
            next unless s["size"] == instance_type
            @prices[instance_type] = s["valueColumns"][0]["prices"]["USD"].to_f
            return @prices[instance_type]
          end
        end
        return 0
      end
    end
  end
end
