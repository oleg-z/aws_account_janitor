module AwsAccountJanitor
  class Account::Billing
    def initialize(args)
      @account_id = args[:account_id]
      @s3_bucket = args[:billing_bucket]
    end

    def logger
      AwsAccountJanitor::Logger.get
    end

    def report(args)
      from = args[:from] || Time.now
      to = args[:to] || Time.now
      get_billing_data(from: from, to: to)
    end

    private

    def round_date_to_day(time)
      Date.parse(time.strftime("%F")).to_time
    end

    def index(field_name, index = nil)
      @fields ||= {}
      @fields[field_name.to_sym] = index if index
      @fields[field_name.to_sym]
    end

    def daily_usage_by_account(save_to, timeframe, r)
      return if r[index(:usage_end_date)].nil? || r[index(:blended_cost)].nil?
      date = DateTime.parse(r[index(:usage_end_date)]).to_time

      date_as_str = date.strftime("%F")
      save_to[r[index(:linked_account_id)]] ||= {}
      save_to[r[index(:linked_account_id)]][date_as_str] ||= 0
      save_to[r[index(:linked_account_id)]][date_as_str]+= r[index(:blended_cost)].to_f
    end

    def daily_instances_by_type(save_to, timeframe, r)
      return if r[index(:usage_end_date)].nil? || r[index(:usage_type)].nil?
      _, instance_size = r[index(:usage_type)].match(/BoxUsage:(.*)/).to_a
      return unless instance_size

      date = DateTime.parse(r[index(:usage_end_date)]).to_time
      return unless timeframe[:from] < date && date < timeframe[:to]

      date_as_str = date.strftime("%F")
      save_to ||= {}
      save_to[date_as_str] ||= {}
      save_to[date_as_str][instance_size] ||= 0
      save_to[date_as_str][instance_size] += r[usage_quantity].to_f.to_i
    end

    def zip_file(year_month)
      s3 = Aws::S3::Client.new(region: 'us-east-1', profile: @account_id)
      local_zip = "./#{@account_id}-aws-billing-detailed.csv.zip"
      remote_zip = "#{@account_id}-aws-billing-detailed-line-items-#{year_month}.csv.zip"
      logger.info("Getting billing zip file: #{File.join(@s3_bucket, remote_zip)}")
      s3.get_object(
        response_target: local_zip,
        bucket: @s3_bucket,
        key: remote_zip
      ).body

      logger.debug("Unpacking billing zip file to #{local_zip}.unzipped")
      `unzip -p #{local_zip} > #{local_zip}.unzipped`
      File.unlink(local_zip)
      "#{local_zip}.unzipped"
    end

    def get_billing_data(timeframe)
      output = {
        usage_by_account: {},
        usage_by_instance_type: {}
      }

      [timeframe[:from].strftime("%Y-%m"), timeframe[:to].strftime("%Y-%m")].uniq.each do |year_month|
        bill = zip_file(year_month)
        logger.info("Processing data for #{year_month}")
        open(bill) do |csv|
          parse_headers = true

          csv.each_line do |line|
            r = line.scan(/"([^"]*)"/).flatten
            if parse_headers
              r.each_with_index do |h, i|
                field_name = h.gsub(/(.)([A-Z])/, "\\1_\\2").downcase
                index(field_name, i)
              end
              parse_headers = false
              next
            end

            daily_usage_by_account(output[:usage_by_account], timeframe, r)
            #daily_instances_by_type(output[:usage_by_instance_type], timeframe, r)
          end
        end
        File.unlink(bill)
      end

      output[:usage_by_account].each { |k, v| v.each { |d, c| output[:usage_by_account][k][d] = c.to_i } }
      output[:usage_by_account].each do |account_id, billing|
        output[:usage_by_account][account_id] = {}
        billing.keys.sort.each { |date| output[:usage_by_account][account_id][date] = billing[date] }
      end

      output
    #rescue => e
      #$stderr.puts "Failed to get billing report for #{@account_id} account"
      #raise e
    end
  end
end
