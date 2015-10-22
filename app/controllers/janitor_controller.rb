class JanitorController < ActionController::Base
  before_action :current_account, :account_list
  layout "ec2"

  AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

  def current_account
    @current_account = params[:account_id] ? AwsAccount.find(params[:account_id]) : AwsAccount.all.first
    @current_account
  end

  def account_list
    @account_list = AwsAccount.all
  end
end
