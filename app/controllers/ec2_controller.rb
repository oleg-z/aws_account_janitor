class Ec2Controller < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  def underutilized_snapshots
    @data_by_region = {}
    @object_type = Aws::EC2::Types::Snapshot
    AWS_REGIONS.each do |region|
      data = get_records(region, :underutilized_ec2_snapshots)
      @data_by_region[region] = data unless data.empty?
    end
    @cost_by_region = calculate_daily_cost(@data_by_region)
  end

  def orphaned_instances
    @data_by_region = {}
    @object_type = Aws::EC2::Types::Instance

    AWS_REGIONS.each do |region|
      data = get_records(region, :ec2_abandoned_instances).sort_by { |i| i["create_time"] }
      @data_by_region[region] = data unless data.empty?
    end
    @cost_by_region = calculate_daily_cost(@data_by_region)
  end

  def underutilized_instances
    @data_by_region = {}
    @object_type = Aws::EC2::Types::Instance
    @cost_by_region = {}
    AWS_REGIONS.each do |region|
      data = get_records(region, :ec2_underutilized_instances).sort_by { |i| i["create_time"] }
      @data_by_region[region] = data unless data.empty?
      @cost_by_region[region] = 0
    end
  end

  def orphaned_asgs
    @data_by_region = {}
    @object_type = Aws::AutoScaling::Types::AutoScalingGroup
    AWS_REGIONS.each do |region|
      data = get_records(region, :tag_violation_asgs)
      @data_by_region[region] = data unless data.empty?
    end

    @cost_by_region = calculate_daily_cost(@data_by_region)
  end

  def orphaned_volumes
    @data_by_region = {}
    @object_type = Aws::EC2::Types::Volume

    AWS_REGIONS.each do |region|
      data = get_records(region, :tag_violation_volumes)
      @data_by_region[region] = data unless data.empty?
    end

    @cost_by_region = calculate_daily_cost(@data_by_region)
  end


end
