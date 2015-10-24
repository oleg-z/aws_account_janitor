class DatabaseController < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  def ddb_orphaned
    @cost_by_region = {}
    @data_by_region = {}

    AWS_REGIONS.each do |region|
      @data_by_region[region] = region_abandoned_ddb(region).sort_by { |i| i["creation_date_time"] }
      @cost_by_region[region] = 0
      @data_by_region[region].each { |i| @cost_by_region[region] += i["daily_cost"].to_f }
    end
  end

  def rds_orphaned
    @cost_by_region = {}
    @data_by_region = {}
    @object_type = Aws::RDS::Types::DBInstance

    AWS_REGIONS.each do |region|
      @data_by_region[region] = region_rds_orphaned(region).sort_by { |i| i["instance_create_time"] }
      @cost_by_region[region] = 0
    end
  end

  private

  def region_abandoned_ddb(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :rds_orphaned_tables)
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
