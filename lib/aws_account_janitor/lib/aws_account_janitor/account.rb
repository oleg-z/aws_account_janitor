require 'aws-sdk'
require 'open-uri'
require 'pry'
require 'json'

require_relative 'managed_objects/abstract'
require_relative 'managed_objects/ec2_instances'
require_relative 'managed_objects/rds_instances'
require_relative 'managed_objects/ddb_tables'

module AwsAccountJanitor
  class Account
    attr_reader :instance_age
    attr_reader :ddb_table_age
    attr_reader :region
    attr_reader :account_number

    def initialize(args = {})
      @region = args[:region] || 'us-east-1'
      Aws.config.update(region: @region)

      @account_number = args[:account_number]
    end

    def ec2
      @ec2 ||= Aws::EC2::Client.new
    end

    def asg
      @asg ||= Aws::AutoScaling::Client.new
    end

    def analyze
      analyze_instances
    end

    def managed_objects
      [
        ManagedObjects::DDBTables.new(account: self),
        ManagedObjects::EC2Instances.new(account: self),
        ManagedObjects::RDSInstances.new(account: self)
      ]
    end

    def abandoned_asgs
      asg
        .describe_auto_scaling_groups
        .auto_scaling_groups
        .select { |asg| asg.instances.size == 0 }
        .collect { |asg| asg.as_json }
    end

    def abandoned_volumes
      volume_filter = [{ name: "status" , values: ["available", "error"] }]
      ec2
        .describe_volumes(filters: volume_filter)
        .volumes
        .collect { |v| v.to_h }
        .each { |v| v["cost"] = volume_cost(v) }
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

    def volume_cost(volume)
      prices = Global.ebs_prices(@region)
      iops_cost = prices[volume[:volume_type]]["per_iops"]*volume[:iops].to_i
      gb_cost = prices[volume[:volume_type]]["per_gb"]*volume[:size].to_i
      ((gb_cost + iops_cost)/30).round(2)
    end
  end
end
