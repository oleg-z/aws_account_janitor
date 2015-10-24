AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

if defined?(Rails) && (Rails.env == 'development')
  Rails.logger = Logger.new(STDOUT)
end

namespace :aws_data do
  desc 'Fetches aws data and save it to databass'
  task :fetch => [:environment, :ec2] do
  end

  task :ec2 => [:rds_orphaned_dbs, :ddb_abandoned_tables, :ec2_abandoned_volumes, :abandoned_instances, :ec2_abandoned_asgs, :ec2_daily_spending_rate] do
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

  def log_action(account, region, message)
    Rails.logger.info("#{account.alias}@#{region}: #{message}")
  end

  def process_accounts
    @credentials = {}
    AwsAccount.all.each do |account|
      AWS_REGIONS.each do |region|
        begin
          switch_account(account, region)
          yield region, account
        rescue Aws::EC2::Errors::AuthFailure => _e
          Rails.logger.info("Failed to switch to '#{account.alias}' account")
        rescue Aws::AutoScaling::Errors::InvalidClientTokenId => _e
          Rails.logger.info("Failed to switch to '#{account.alias}' account")
        rescue => e
          log_action(account, region, "Failed to complete action block: #{e}")
        end
      end
    end
  end

  task :abandoned_instances do
    process_accounts { |region, account|
      log_action(account, region, "Getting abandoned instances")
      acc = AwsAccountJanitor::Account.new(region: region)

      data =
        acc
        .abandoned_instances
        .sort_by { |i| i["launch_time"] }

      r = AwsRecord.new()
      r.data_type = :ec2_abandoned_instances
      r.account_id = account.id
      r.aws_region = region
      r.data = data
      r.save
    }
  end

  task :ec2_daily_spending_rate do
    process_accounts { |region, account|
      log_action(account, region, "Getting ec2 daily spending rate")
      acc = AwsAccountJanitor::Account.new(region: region)
      r = AwsRecord.new()
      r.account_id = account.id
      r.data_type = :ec2_daily_rate
      r.aws_region = region
      r.data = acc.daily_spending_rate
      r.save
    }
  end

  task :ec2_abandoned_asgs do
    process_accounts { |region, account|
      log_action(account, region, "Getting ec2 abandoned ASGs")
      acc = AwsAccountJanitor::Account.new(region: region)
      r = AwsRecord.new()
      r.account_id = account.id
      r.data_type = :ec2_abandoned_asgs
      r.aws_region = region
      r.data = acc.abandoned_asgs
      r.save
    }
  end

  task :ec2_abandoned_volumes do
    process_accounts { |region, account|
      log_action(account, region, "Getting ec2 abandoned volumes")
      acc = AwsAccountJanitor::Account.new(region: region)
      r = AwsRecord.new()
      r.account_id = account.id
      r.data_type = :ec2_abandoned_volumes
      r.aws_region = region
      r.data = acc.abandoned_volumes
      r.save
    }
  end

  task :ddb_abandoned_tables do
    process_accounts { |region, account|
      log_action(account, region, "Getting ddb tables")
      acc = AwsAccountJanitor::Account.new(region: region)

      r = AwsRecord.new()
      r.account_id = account.id
      r.data_type = :ddb_abandoned_tables
      r.aws_region = region
      r.data = acc.ddb_abandoned_tables
      r.save
    }
  end

  task :rds_orphaned_dbs do
    process_accounts { |region, account|
      log_action(account, region, "Getting orphaned rds DBs")
      acc = AwsAccountJanitor::Account.new(region: region)

      r = AwsRecord.new()
      r.account_id = account.id
      r.data_type = :rds_orphaned_tables
      r.aws_region = region
      r.data = acc.rds_orphaned_dbs
      r.save
    }
  end
end
