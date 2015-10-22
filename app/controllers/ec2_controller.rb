class Ec2Controller < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Live

  def abandoned_instances
    @abandoned_instances = {}
    @spending_rate_by_region = {}

    AWS_REGIONS.each do |region|
      @abandoned_instances[region] = region_abandoned_instances(region).sort_by { |i| i["launch_time"] }
      @spending_rate_by_region[region] = 0
      @abandoned_instances[region].each { |i| @spending_rate_by_region[region] += i["daily_cost"].to_f }
    end
  end

  def abandoned_asgs
    @abandoned_asgs = {}
    AWS_REGIONS.each do |region|
      @abandoned_asgs[region] = region_abandoned_asgs(region)
    end
  end

  def abandoned_volumes
    @abandoned_volumes = {}
    @spending_rate_by_region = {}
    AWS_REGIONS.each do |region|
      @abandoned_volumes[region] = region_abandoned_volumes(region)
      @spending_rate_by_region[region] = 0
      @abandoned_volumes[region].each{ |v| @spending_rate_by_region[region] += v["cost"].to_f }
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

  def current_account
    @current_account = params[:account_id] ? AwsAccount.find(params[:account_id]) : AwsAccount.all.first
    @current_account
  end
end
