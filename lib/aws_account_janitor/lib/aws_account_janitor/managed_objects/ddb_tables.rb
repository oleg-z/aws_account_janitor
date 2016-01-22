module AwsAccountJanitor
  class ManagedObjects
    class DDBTables < Abstract
      private

      def ec2
        @ec2 ||= Aws::EC2::Client.new
      end

      def all
        ddb = Aws::DynamoDB::Client.new

        next_token = nil
        data = []

        loop do
          tables = ddb.list_tables(exclusive_start_table_name: next_token)
          data += tables
            .table_names
            .collect { |t| ddb.describe_table(table_name: t).table }
            .each { |t| standardize(t) }

          next_token = tables.last_evaluated_table_name
          break unless next_token
        end

        data
      end

      def standardize(t)
        t = to_hash(t)
        t[:daily_cost] = table_daily_cost(t) * 24
        t[:create_time] = t[:creation_date_time]

        cloudtrail = Aws::CloudTrail::Client.new(region: Aws.config[:region])
        binding.pry
      end

      def table_daily_cost(t)
        ddb_prices = Global.ddb_prices(Aws.config[:region])
        (t[:provisioned_throughput][:read_capacity_units]/50) * ddb_prices["reads"] + (t[:provisioned_throughput][:write_capacity_units]/10) * ddb_prices["writes"]
      end
    end
  end
end
