module AwsAccountJanitor
  class ManagedObjects
    class RDSInstances < Abstract
      def improperly_tagged
        { rds_orphaned_tables: all { |o| violate_tag_rules?(o) } }
      end

      private

      def rds
        @rds ||= Aws::RDS::Client.new
      end

      def all
        next_token = nil
        data = []

        loop do
          instances = rds.describe_db_instances(marker: next_token)

          data += instances
            .db_instances
            .collect(&:to_h)
            .each { |i| standardize(i) }
            .select { |db| yield db }
            .each { |db| standardize(db) }

          next_token = instances.marker
          break unless next_token
        end

        data
      end

      def resource_arn(db)
        return nil unless account.account_number
        "arn:aws:rds:#{Aws.config[:region]}:#{account.account_number}:db:#{db[:db_instance_identifier]}"
      end

      def tags(db)
        rds.list_tags_for_resource(resource_name: resource_arn(db)).tag_list
      rescue
        []
      end

      def standardize(db)
        db[:daily_cost] = 0
        db[:create_time] = db[:instance_create_time]
        db[:tags] = tags(db)
      end
    end
  end
end
