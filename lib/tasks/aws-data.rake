AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

namespace :aws_data do
  desc 'Fetches aws data and save it to databass'

  task :fetch do
    if Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    else
      Rails.logger       = Logger.new(Rails.root.join('log', 'daemon.log'))
    end

    Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)

    if Rails.env.production?
      Process.daemon(true, true)
      #if ENV['PIDFILE']
      #  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid }
      #end

      Signal.trap('TERM') { abort }

      Rails.logger.info "Start daemon..."

      loop do
        Rake::Task['aws_data:fetch_internal'].invoke
        sleep 900
      end
    else
      Rake::Task['aws_data:fetch_internal'].invoke
    end
  end

  task :fetch_internal => [:environment, :ec2] do
  end

  task :ec2 do
    AwsAccount.all.each do |account|
      @credentials = {}
      AWS_REGIONS.each do |region|
        begin
          switch_account(account, region)
          janitor = AwsAccountJanitor::Account.new(region: region, account_number: account.identifier)

          janitor.managed_objects.each do |object|
            object.orphaned.each do |data_label, data|
              r = AwsRecord.find_by(account_id: account.id, data_type: data_label, aws_region: janitor.region)
              if r
                r.data = data
              else
                r = AwsRecord.new(
                  data_type:  data_label,
                  account_id: account.id,
                  aws_region: janitor.region,
                  data:       data
                )
              end
              r.save
            end
          end

          #log_action(account, region, "Getting ec2 orphaned ASGs")
          #orphaned_asgs(account, janitor)
          #
          #log_action(account, region, "Getting ec2 daily spending rate")
          #instances_spending_rate(account, janitor)
          #
          #log_action(account, region, "Getting ec2 abandoned volumes")
          #orphaned_volumes(account, janitor)
          #
          #log_action(account, region, "Getting ddb tables")
          #orphaned_ddb_tables(account, janitor)
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

  def instances_spending_rate(account, janitor)
    r = AwsRecord.new(
      data_type:  :ec2_daily_rate,
      account_id: account.id,
      aws_region: janitor.region,
      data:       janitor.daily_spending_rate
    )
    r.save
  end

  def orphaned_asgs(account, janitor)
    r = AwsRecord.new(
      data_type:  :ec2_abandoned_asgs,
      account_id: account.id,
      aws_region: janitor.region,
      data:       janitor.abandoned_asgs
    )
    r.save
  end

  def orphaned_volumes(account, janitor)
    r = AwsRecord.new(
      data_type:  :ec2_abandoned_volumes,
      account_id: account.id,
      aws_region: janitor.region,
      data:       janitor.abandoned_volumes
    )
    r.save
  end

  def orphaned_ddb_tables(account, janitor)
    r = AwsRecord.new(
      data_type:  :ddb_abandoned_tables,
      account_id: account.id,
      aws_region: janitor.region,
      data:       janitor.ddb_abandoned_tables
    )
    r.save
  end

  def orphaned_rds(account, janitor)
    r = AwsRecord.new(
      data_type:  :rds_orphaned_tables,
      account_id: account.id,
      aws_region: janitor.region,
      data:       janitor.rds_orphaned_dbs
    )
    r.save
  end
end
