class DatabaseController < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  def underutilized_ddb
    @data_by_region = {}
    @object_type = Aws::DynamoDB::Table
    @cost_by_region = {}
    AWS_REGIONS.each do |region|
      data = get_records(region, "underutilized_ddb_tables").sort_by { |i| i["daily_cost"] }
      @data_by_region[region] = data unless data.empty?
    end
    @cost_by_region = calculate_daily_cost(@data_by_region)

  end

  def orphaned_rds
    @cost_by_region = {}
    @data_by_region = {}
    @object_type = Aws::RDS::Types::DBInstance

    AWS_REGIONS.each do |region|
      data = region_rds_orphaned(region).sort_by { |i| i["instance_create_time"] }
      next if data.empty?
      @data_by_region[region] = data
      @cost_by_region[region] = 0
    end
  end

  private

  def region_abandoned_ddb(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :ddb_abandoned_tables)
      .order("created_at DESC")
      .limit(1)
      .last
    return [] unless r
    r.data
  end

  def region_rds_orphaned(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :rds_orphaned_tables)
      .order("created_at DESC")
      .limit(1)
      .last
    return [] unless r
    r.data
  end

  def www
    "https://console.aws.amazon.com/dynamodb/home?region=us-east-1#table:name=us-east-1.base-aporubov-add-mia.dev.aims.account"
  end
end
