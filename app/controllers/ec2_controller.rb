class Ec2Controller < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  def orphaned_instances
    @abandoned_instances = {}
    @spending_rate_by_region = {}
    @object_type = Aws::EC2::Types::Instance

    AWS_REGIONS.each do |region|
      data = region_abandoned_instances(region).sort_by { |i| i["launch_time"] }
      next if data.empty?
      @abandoned_instances[region] = data
      @spending_rate_by_region[region] = 0
      data.each { |i| @spending_rate_by_region[region] += i["daily_cost"].to_f }
    end
  end

  def orphaned_asgs
    @data_by_region = {}
    @object_type = Aws::AutoScaling::Types::AutoScalingGroup
    AWS_REGIONS.each do |region|
      data = region_abandoned_asgs(region)
      next if data.empty?
      @data_by_region[region] = data
    end
  end

  def orphaned_volumes
    @cost_by_region = {}
    @data_by_region = {}
    @object_type = Aws::EC2::Types::Volume

    AWS_REGIONS.each do |region|
      data = region_abandoned_volumes(region)
      next if data.empty?
      @data_by_region[region] = data
      @cost_by_region[region] = 0
      @data_by_region[region].each { |v| @cost_by_region[region] += v["cost"].to_f }
    end
  end

  private
  def spending_rate(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :ec2_daily_rate)
      .order("created_at DESC")
      .limit(1)
      .last
    return 0 unless r
    r.data.to_i
  end

  def region_abandoned_instances(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :ec2_abandoned_instances)
      .order("created_at DESC")
      .limit(1)
      .last
    return [] unless r

    r.data.to_a
  end

  def region_abandoned_asgs(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :ec2_abandoned_asgs)
      .order("created_at DESC")
      .limit(1)
      .last
    return [] unless r
    r.data
  end

  def region_abandoned_volumes(region)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: :ec2_abandoned_volumes)
      .order("created_at DESC")
      .limit(1)
      .last
    return [] unless r
    r.data
  end
end
