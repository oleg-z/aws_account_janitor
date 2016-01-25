module AwsAccountJanitor
  class ManagedObjects
    class EC2Instances < Abstract
      def improperly_tagged
        { ec2_abandoned_instances: all.select { |o| violate_tag_rules?(o) } }
      end

      def underutilized
        cloudwatch = Aws::CloudWatch::Client.new(region: Aws.config[:region])

        all.each do |i|
          metrics = cloudwatch.get_metric_statistics(
              namespace: 'AWS/EC2',
              metric_name: 'CPUUtilization',
              dimensions: [ { name: "InstanceId", value: i[:instance_id] } ],
              start_time: Time.now - 86400*7,
              end_time: Time.now ,
              statistics: ["Maximum"],
              period: 86400*7,
              unit: "Percent"
            ).datapoints
          i[:cpu_utilization] = metrics.first.maximum
        end

        { ec2_underutilized_instances: all.select { |o| o[:cpu_utilization] < 20 } }
      end

      private

      def ec2
        @ec2 ||= Aws::EC2::Client.new
      end

      def all
        return @all if @all
        instance_filter = [
          { name: "instance-state-name" , values: ["running"] }
        ]

        next_token = nil
        data = []

        loop do
          instances = ec2.describe_instances(filters: instance_filter, max_results: 100, next_token: next_token)
          data += instances
            .reservations
            .collect { |r| r.instances }
            .compact
            .flatten
            .collect { |i| standardize(i) }
          next_token = instances.next_token
          break unless next_token
        end

        @all = data
      end

      def standardize(i)
        i = to_hash(i)
        i[:daily_cost] = instance_price(i[:instance_type]) * 24
        i[:create_time] = i[:launch_time]
        i
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
