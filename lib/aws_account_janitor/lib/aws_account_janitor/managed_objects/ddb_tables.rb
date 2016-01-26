module AwsAccountJanitor
  class ManagedObjects
    class DDBTables < Abstract
      LABEL = 'ddb_tables'

      def underutilized
        cloudwatch = Aws::CloudWatch::Client.new(region: Aws.config[:region])

        tables_stats = all.collect do |t|
          next unless t[:create_time] < Time.now - 5.days

          read_metrics = cloudwatch.get_metric_statistics(
            namespace: 'AWS/DynamoDB',
            metric_name: 'ConsumedReadCapacityUnits',
            dimensions: [ { name: "TableName", value: t[:table_name] } ],
            start_time: Time.now - 86400*7,
            end_time: Time.now ,
            statistics: ["Sum"],
            period: 86400*7,
            unit: "Count"
          ).datapoints.first

          write_metrics = cloudwatch.get_metric_statistics(
            namespace: 'AWS/DynamoDB',
            metric_name: 'ConsumedWriteCapacityUnits',
            dimensions: [ { name: "TableName", value: t[:table_name] } ],
            start_time: Time.now - 86400*7,
            end_time: Time.now ,
            statistics: ["SampleCount"],
            period: 86400*7,
            unit: "Count"
          ).datapoints.first

          table_operations = [read_metrics, write_metrics].compact.collect{ |m| m.sum.to_i }.sum

          t[:utilization] = 100
          t[:utilization] = 0 if table_operations == 0

          t
        end

        { "underutilized_#{LABEL}" => tables_stats.compact.select { |o| o[:utilization] < 30 } }
      end

      private

      def all
        return @all if @all
        ddb = Aws::DynamoDB::Client.new

        next_token = nil
        data = []

        loop do
          tables = ddb.list_tables(exclusive_start_table_name: next_token)
          data += tables
            .table_names
            .collect do |t|
              begin
                ddb.describe_table(table_name: t).table
              rescue
                binding.pry
              end
            end
            .collect { |t| standardize(t) }

          next_token = tables.last_evaluated_table_name
          break unless next_token
        end

        @all = data
      end

      def standardize(t)
        t = to_hash(t)
        t[:daily_cost] = table_daily_cost(t) * 24
        t[:create_time] = t[:creation_date_time]
        t
      end

      def table_daily_cost(t)
        ddb_prices = Global.ddb_prices(Aws.config[:region])
        (t[:provisioned_throughput][:read_capacity_units]/50) * ddb_prices["reads"] + (t[:provisioned_throughput][:write_capacity_units]/10) * ddb_prices["writes"]
      rescue
        binding.pry
      end
    end
  end
end
