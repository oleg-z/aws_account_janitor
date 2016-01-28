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
      task_frequency.each do |task_name, frequency|
        last_execution[task_name] ||= Time.now - frequency - 1
        next if Time.now - last_execution[task_name] < frequency

        begin
          Rake::Task["aws_data:#{task_name}"].invoke
        rescue => e
          Rails.logger.error("Failed to complete action '#{task_name}' block: #{e}")
        ensure
          last_execution[task_name] = Time.now
        end
      end
      sleep 60
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
      JanitorUi::SUPPORTED_AWS_REGIONS.each do |region|
        janitor = error_trap(nil) {
          switch_account(account, region)
          janitor = AwsAccountJanitor::Account.new(region: region, account_number: account.identifier)
        }
        next unless janitor

        janitor.managed_objects.each do |object|
          {}
            .merge(error_trap({}) { object.underutilized })
            .merge(error_trap({}) { object.improperly_tagged })
            .each do |data_label, data|
              r = AwsRecord.find_by(account_id: account.id, data_type: data_label, aws_region: janitor.region)
              r ? r.data = data : r = AwsRecord.new(data_type: data_label, account_id: account.id, aws_region: janitor.region, data: data)
              r.save
            end
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

  def error_trap(return_value)
    yield
  rescue Aws::EC2::Errors::AuthFailure => _e
    Rails.logger.error("Authentication failure: #{e}")
    return return_value
  rescue Aws::AutoScaling::Errors::InvalidClientTokenId => _e
    Rails.logger.error("Authentication failure: #{e}")
    return return_value
  rescue => e
    Rails.logger.error("Error: #{e}")
    return return_value
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
