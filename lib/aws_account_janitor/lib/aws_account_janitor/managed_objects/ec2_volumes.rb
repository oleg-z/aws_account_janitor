module AwsAccountJanitor
  class ManagedObjects
    class EC2Volumes < Abstract
      def improperly_tagged
        { "tag_violation_volumes" => all.select { |o| violate_tag_rules?(o) } }
      end

      def underused
      end

      private

      def ec2
        @ec2 ||= Aws::EC2::Client.new
      end

      def all
        volume_filter = [{ name: "status" , values: ["available", "error"] }]
        ec2
          .describe_volumes(filters: volume_filter)
          .volumes
          .collect { |v| standardize(v) }
      end

      def standardize(v)
        v = to_hash(v)
        v[:daily_cost] = volume_cost(v)
        v[:create_time] = v[:create_time]
        v[:tags] ||= []
        v
      end

      def volume_cost(volume)
        prices = Global.ebs_prices(Aws.config[:region])
        iops_cost = prices[volume[:volume_type]]["per_iops"]*volume[:iops].to_i
        gb_cost = prices[volume[:volume_type]]["per_gb"]*volume[:size].to_i
        ((gb_cost + iops_cost)/30).round(2)
      end
    end
  end
end
