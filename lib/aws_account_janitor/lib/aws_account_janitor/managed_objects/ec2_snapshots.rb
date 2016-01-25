module AwsAccountJanitor
  class ManagedObjects
    class EC2Snapshots < Abstract
      def improperly_tagged
        { "tag_violation_snapshots" => all.select { |o| violate_tag_rules?(o) } }
      end

      private

      def ec2
        @ec2 ||= Aws::EC2::Client.new
      end

      def all
        snapshots = []
        return [] if @account.account_number.to_s.empty?

        next_token = nil
        filter = [{ name: "owner-id" , values: [@account.account_number] }]
        loop do
          r = ec2.describe_snapshots(filters: filter, next_token: next_token)
          snapshots += r.snapshots.collect { |v| standardize(v) }
          next_token = r.next_token
          break if next_token.nil?
        end

        snapshots
      end

      def standardize(v)
        v = to_hash(v)
        v[:daily_cost] = snapshot_cost(v)
        v[:create_time] = v[:start_time]
        v
      end

      def snapshot_cost(s)
        # assuming that only 15% actually unique
        ((0.1 * 0.095 * s[:volume_size])/30).round(5)
      end
    end
  end
end
