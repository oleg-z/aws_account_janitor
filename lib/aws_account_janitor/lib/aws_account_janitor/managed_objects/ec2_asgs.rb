module AwsAccountJanitor
  class ManagedObjects
    class EC2Asgs < Abstract
      def improperly_tagged
        { "tag_violation_asgs" => all.select { |o| violate_tag_rules?(o) }  }
      end

      private

      def asg
        @asg ||= Aws::AutoScaling::Client.new
      end

      def all
        asg
          .describe_auto_scaling_groups
          .auto_scaling_groups
          .collect { |asg| asg.to_h }
          .collect { |asg| standardize(asg)  }
      end

      def standardize(a)
        a = to_hash(a)
        a[:daily_cost] = 0
        a[:create_time] = a["created_time"]
        a
      end
    end
  end
end
