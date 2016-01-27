require 'aws-sdk'
require 'open-uri'
require 'pry'
require 'json'
require 'date'

require_relative 'managed_objects/abstract'
require_relative 'managed_objects/ec2_instances'
require_relative 'managed_objects/rds_instances'
require_relative 'managed_objects/ddb_tables'
require_relative 'managed_objects/ec2_asgs'
require_relative 'managed_objects/ec2_volumes'
require_relative 'managed_objects/ec2_snapshots'

module AwsAccountJanitor
  class Account
    require_relative 'account/billing'

    attr_reader :instance_age
    attr_reader :ddb_table_age
    attr_reader :region
    attr_reader :account_number

    def initialize(args = {})
      @region = args[:region] || 'us-east-1'
      Aws.config.update(region: @region)

      @account_number = args[:account_number]
      if args[:billing_bucket]
        @billing = Billing.new(account_id: account_number, billing_bucket: args[:billing_bucket])
      end
    end

    def billing
      return {} if @billing.nil?
      return @billing.report
    end

    def ec2
      @ec2 ||= Aws::EC2::Client.new
    end

    def managed_objects
      [
        ManagedObjects::EC2Snapshots.new(account: self),
        ManagedObjects::DDBTables.new(account: self),
        ManagedObjects::EC2Asgs.new(account: self),
        ManagedObjects::EC2Volumes.new(account: self),
        ManagedObjects::EC2Instances.new(account: self),
        ManagedObjects::RDSInstances.new(account: self)
      ]
    end

    def daily_spending_rate
      running_instances = [
        { name: "instance-state-name" , values: ["running"] }
      ]

      spending_rate = 0
      ec2.describe_instances(filters: running_instances).reservations.collect do |r|
        r.instances.each do |i|
          spending_rate += instance_price(i["instance_type"])
        end
      end

      spending_rate * 24
    end

    private


  end
end
