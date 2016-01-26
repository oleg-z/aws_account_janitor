AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

namespace :aws_data do
  desc 'Fetches aws data and save it to databass'

  task :fetch => [:environment, :logger] do
    if Rails.env.production?
      Process.daemon(true, true)
      #if ENV['PIDFILE']
      #  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid }
      #end

      Signal.trap('TERM') { abort }
      Rails.logger.info "Start daemon..."
    end

    task_frequency = {
      fetch_internal: 1800,
      billing: 3600 * 3
    }

    last_execution = {}
    loop do
      task_frequency.each do |task, frequency|
        if Time.now.to_i - last_execution[task].to_i < frequency
          puts "Next execution in #{Time.now.to_i - last_execution[task].to_i}"
          next
        end

        begin
          Rake::Task["aws_data:#{task}"].invoke
        rescue => e
          log_action(account, region, "Failed to complete action '#{task}' block: #{e}")
        ensure
          last_execution[task] = Time.now
          sleep 60
        end
      end
    end
  end

  task :logger => [:environment] do
    if Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    else
      Rails.logger = Logger.new(Rails.root.join('log', 'daemon.log'))
    end
    Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)
  end

  task :fetch_internal => [:logger, :ec2] do
  end

  task :ec2 do
    AwsAccount.all.each do |account|
      @credentials = {}
      AWS_REGIONS.each do |region|
        begin
          switch_account(account, region)
          janitor = AwsAccountJanitor::Account.new(region: region, account_number: account.identifier)

          janitor.managed_objects.each do |object|
            {}
              .merge(object.underutilized)
              .merge(object.improperly_tagged)
              .each do |data_label, data|
                r = AwsRecord.find_by(account_id: account.id, data_type: data_label, aws_region: janitor.region)
                r ? r.data = data : r = AwsRecord.new(data_type: data_label, account_id: account.id, aws_region: janitor.region, data: data)
                r.save
              end
          end
        rescue Aws::EC2::Errors::AuthFailure => _e
          Rails.logger.error("Failed to switch to '#{account.alias}' account")
        rescue Aws::AutoScaling::Errors::InvalidClientTokenId => _e
          Rails.logger.error("Failed to switch to '#{account.alias}' account")
        rescue => e
          log_action(account, region, "Failed to complete action block: #{e}")
        end
      end
    end
  end

  task :billing => [:logger] do
    AwsAccount.all.each do |account|
      next if account.billing_bucket.to_s.strip == ""
      @credentials = {}
      begin
        switch_account(account, "us-east-1")
        janitor = AwsAccountJanitor::Account.new(
          region: "us-east-1",
          account_number: account.identifier,
          billing_bucket: account.billing_bucket
        )
        janitor.billing[:usage_by_account].each do |account_id, daily_data|
          daily_data.each do |date, value|
            r = AwsUsageRecord.find_by(data_type: 'daily_cost', account_id: account_id, date: date)

            if r.nil?
              r = AwsUsageRecord.new(
                data_type:  'daily_cost',
                account_id: account_id,
                date:       date,
                data:       value
              )
              r.save
            elsif r.data != value
              r.data = value
              r.save
            end
          end
        end
      rescue Aws::EC2::Errors::AuthFailure => _e
        Rails.logger.error("Failed to switch to '#{account.alias}' account")
      rescue Aws::AutoScaling::Errors::InvalidClientTokenId => _e
        Rails.logger.error("Failed to switch to '#{account.alias}' account")
      rescue => e
        log_action(account, region, "Failed to complete action block: #{e}")
      end
    end
  end

  def log_action(account, region, message)
    Rails.logger.info("#{account.alias}@#{region}: #{message}")
  end

  def switch_account(account, region)
    @credentials ||= {}
    @credentials[account.id] ||= {}

    credentials = nil
    Rails.logger.info("Authenticating to #{account.alias}@#{region}")

    # switching region
    Aws.config.update(region: region)

    # updating credentials with current access and secrets
    credentials = Aws::Credentials.new(account.access_key, account.secret_key)
    Aws.config.update(credentials: credentials)

    # assuming role if defined
    unless account.role.strip.empty?
      tmp_credentials =
        Aws::STS::Client.new(access_key_id: account.access_key, secret_access_key: account.secret_key)
        .assume_role(role_arn: account.role, duration_seconds: 3600, role_session_name: "account-janitor")
        .credentials

      credentials = Aws::Credentials.new(
        tmp_credentials.access_key_id,
        tmp_credentials.secret_access_key,
        tmp_credentials.session_token
      )
      Aws.config.update(credentials: credentials)
    end
  end
end
