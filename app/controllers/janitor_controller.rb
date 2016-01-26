class JanitorController < ActionController::Base
  before_action :current_account, :account_list
  layout "admin"

  AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

  def update_tags
    object_type = params[:object_type]
    region = params[:region]

    @current_account.authenticate(region)
    params[:objects].each do |object_id|
      case object_type
      when "Aws::EC2::Types::Volume"
        o = Aws::EC2::Volume.new(object_id)
        o.create_tags(
          tags: [
            { key: 'Owner', value: params[:owner].strip },
            { key: 'Project', value: params[:project].strip }
          ]
        )
      when "Aws::AutoScaling::Types::AutoScalingGroup"
        o = Aws::EC2::Instance.new(object_id)
        o.create_tags(
          tags: [
            { key: 'Owner', value: params[:owner].strip },
            { key: 'Project', value: params[:project].strip }
          ]
        )
      when "Aws::EC2::Types::Instance"
        o = Aws::EC2::Instance.new(object_id)
        o.create_tags(
          tags: [
            { key: 'Owner', value: params[:owner].strip },
            { key: 'Project', value: params[:project].strip }
          ]
        )
      when "Aws::RDS::Types::DBInstance"
        o = Aws::RDS::Client.new
        resource_name = "arn:aws:rds:#{region}:#{@current_account.identifier}:db:#{object_id}"

        o.add_tags_to_resource(
          resource_name: resource_name,
          tags: [
            { key: 'Owner', value: params[:owner].strip },
            { key: 'Project', value: params[:project].strip }
          ]
        )
      end
    end

    render json: { message: "Object has been tagged" }
  rescue => e
    Rails.logger.error(e)
    render json: { error: "Failed to tag an object" }
  end

  def example
    render layout: false
  end

  protected

  def current_account
    @current_account = params[:account_id] ? AwsAccount.find(params[:account_id]) : AwsAccount.all.first
    @current_account
  end

  def account_list
    @account_list = AwsAccount.all
  end

  def get_records(region, data_type)
    r = AwsRecord
      .where(account_id: current_account.id, aws_region: region, data_type: data_type)
      .order("created_at DESC")
      .limit(1)
      .last
    return [] unless r

    r.data.to_a
  end

  def calculate_daily_cost(data_by_region)
    @spending_rate_by_region = {}
    data_by_region.each do |region, data|
      @spending_rate_by_region[region] = @data_by_region[region].inject(0) { |sum, i| sum += i["daily_cost"].to_f }.round(2)
    end
    @spending_rate_by_region
  end
end
