class DashboardController < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  DATA_TYPE_CONTROLLER_MAP = {
    "ec2_abandoned_instances"     => { controller: 'ec2', action: 'orphaned_instances', label: 'EC2 Instances' },
    "ec2_underutilized_instances" => { controller: 'ec2', action: 'underutilized_instances', label: 'EC2 Instances' },
    "tag_violation_volumes"       => { controller: 'ec2', action: 'orphaned_volumes', label: 'EC2 Volumes'},
    "tag_violation_asgs"          => { controller: 'ec2', action: 'orphaned_asgs', label: 'EC2 ASGs' },
    "underutilized_ec2_snapshots" => { controller: 'ec2', action: 'underutilized_snapshots', label: 'EC2 Snapshots' },
    "ddb_abandoned_tables"        => { controller: 'database', action: 'orphaned_ddb', label: 'DDB Tables' },
    "rds_orphaned_tables"         => { controller: 'database', action: 'orphaned_rds', label: 'RDS Instances' },
    "underutilized_ddb_tables"    => { controller: 'database', action: 'underutilized_ddb', label: 'DDB Tables' },
  }

  def tag_violations
    records = AwsRecord
      .order("created_at DESC")
      .group("account_id, data_type, aws_region")

    @review_required = {}

    types = [:ec2_abandoned_instances, :tag_violation_volumes, :rds_orphaned_tables]

    AwsAccount.all.each do |account|
      records = AwsRecord
        .where(account_id: account.id)
        .order("created_at DESC")
        .group("data_type, aws_region")

      records
        .select { |r| r.data.kind_of?(Array) && r.data.size > 0 }
        .sort_by { |r| r.data.size }
        .each do |r|
          next unless r.account_id
          next unless types.include?(r.data_type.to_sym)

          @review_required[account.id] ||= {}
          @review_required[account.id][r.data_type] = @review_required[account.id][r.data_type].to_i + r.data.size
        end
    end

    @data_type_controller_map = DATA_TYPE_CONTROLLER_MAP
  end

  def underutilized
    @review_required = {}

    types = [:ec2_underutilized_instances, :underutilized_ddb_tables, :underutilized_ec2_snapshots]

    AwsAccount.all.each do |account|
      records = AwsRecord
        .where(account_id: account.id)
        .order("created_at DESC")
        .group("data_type, aws_region")

      records
        .select { |r| r.data.kind_of?(Array) && r.data.size > 0 }
        .sort_by { |r| r.data.size }
        .each do |r|
          next unless r.account_id
          next unless types.include?(r.data_type.to_sym)

          @review_required[account.id] ||= {}
          @review_required[account.id][r.data_type] = @review_required[account.id][r.data_type].to_i + r.data.size
        end
    end

    @data_type_controller_map = DATA_TYPE_CONTROLLER_MAP
  end

  def usage_dashboard
    @daily_usage = {}
    @timeframes = {
      "2 weeks"  => 86400 * 14,
      "1 month"  => 86400 * 30,
      "2 months" => 86400 * 60,
      "3 months" => 86400 * 90
    }

    @selected_timeframe = @timeframes[params["timeframe"]] ? params["timeframe"] : "2 weeks"

    @daily_usage_sorted = {}
    AwsUsageRecord
      .where("data_type = ? AND ? < date AND date < ?", 'daily_cost', (Time.now - @timeframes[@selected_timeframe]), Time.now)
      .order("date ASC")
      .each do |r|
        @daily_usage[r.account_id] ||= {}
        @daily_usage[r.account_id][r.date] = r.data
      end

    @daily_usage_sorted = {}

    # sort by average spending
    accounts = AwsAccount.all
    @daily_usage
      .sort_by { |k, v| (v.values.collect(&:to_i).sum)/v.values.size }
      .reverse
      .each do |i|
        managed_account = accounts.detect { |a| a.identifier == i[0] }
        @daily_usage_sorted[i[0]] = {
          spending: i[1],
          threshold: managed_account ? managed_account.spending_threshold : 0
        }
      end

    @daily_usage = @daily_usage_sorted

    to_javascript usage_data: @daily_usage
  end

end
