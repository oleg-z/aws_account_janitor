require_relative 'extensions/time'
require_relative 'extensions/struct'
require_relative 'aws_account_janitor/version'
require_relative 'aws_account_janitor/account'
require_relative 'aws_account_janitor/global'

module AwsAccountJanitor
  def self.start
    account = AwsAccountJanitor::Account.new(region: 'us-east-1')
    account.abandoned_instances

    #account.spending_rate
  end
end
