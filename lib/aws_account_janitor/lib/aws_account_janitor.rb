require_relative 'extensions/time'
require_relative 'extensions/struct'
require_relative 'aws_account_janitor/version'
require_relative 'aws_account_janitor/account'
require_relative 'aws_account_janitor/global'

module AwsAccountJanitor
  SUPPORTED_AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1 ap-northeast-2)

  def self.start
    account = AwsAccountJanitor::Account.new(region: 'us-east-1')
    account.abandoned_instances

    #account.spending_rate
  end
end
