class JanitorController < ActionController::Base
  before_action :current_account, :account_list
  layout "ec2"

  AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

  def update_tags
    object_type = params[:object_type]
    region = params[:region]

    @current_account.authenticate(region)
    case object_type
    when "Aws::EC2::Types::Volume"
      params[:objects].each do |object_id|
        o = Aws::EC2::Volume.new(object_id)
        o.create_tags(
          tags: [
            { key: 'Owner', value: params[:owner].strip },
            { key: 'Project', value: params[:project].strip }
          ]
        )
      end
    when "Aws::AutoScaling::Types::AutoScalingGroup"
      params[:objects].each do |object_id|
        o = Aws::EC2::Instance.new(object_id)
        o.create_tags(
          tags: [
            { key: 'Owner', value: params[:owner].strip },
            { key: 'Project', value: params[:project].strip }
          ]
        )
      end
    when "Aws::EC2::Types::Instance"
      params[:objects].each do |object_id|
        o = Aws::EC2::Instance.new(object_id)
        o.create_tags(
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

  protected

  def current_account
    @current_account = params[:account_id] ? AwsAccount.find(params[:account_id]) : AwsAccount.all.first
    @current_account
  end

  def account_list
    @account_list = AwsAccount.all
  end


end
