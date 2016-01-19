class JanitorController < ActionController::Base
  before_action :current_account, :account_list
  layout "admin"

  AWS_REGIONS = %w(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 sa-east-1 ap-southeast-2 ap-southeast-1 ap-northeast-1)

  DATA_TYPE_CONTROLLER_MAP = {
    "ec2_abandoned_instances" => { controller: 'ec2', action: 'orphaned_instances' },
    "ec2_abandoned_volumes"   => { controller: 'ec2', action: 'orphaned_volumes' },
    "ec2_abandoned_asgs"      => { controller: 'ec2', action: 'orphaned_asgs' },
    "ddb_abandoned_tables"    => { controller: 'database', action: 'orphaned_ddb' },
    "rds_orphaned_tables"     => { controller: 'database', action: 'orphaned_rds' }
  }

  def dashboard
    records = AwsRecord
      .order("created_at DESC")
      .group("account_id, data_type, aws_region")

    @review_required = {}

    AwsAccount.all.each do |account|
      records = AwsRecord
        .where(account_id: account.id)
        .order("created_at DESC")
        .group("data_type, aws_region")

      records
        .select { |r| r.data.kind_of?(Array) && r.data.size > 0 }
        .sort_by { |r| r.data.size }
        .each do |r|
          next unless r.account_id
          next unless DATA_TYPE_CONTROLLER_MAP[r.data_type]

          @review_required[account.id] ||= {}
          @review_required[account.id][r.data_type] = @review_required[account.id][r.data_type].to_i + r.data.size
        end
    end

    @data_type_controller_map = DATA_TYPE_CONTROLLER_MAP
  end

  def usage_dashboard
    @daily_usage = {}
    @timeframes = {
      "2 weeks"  => 86400 * 14,
      "1 month"  => 86400 * 30,
      "2 months" => 86400 * 60,
      "3 months" => 86400 * 90
    }

    @selected_timeframe = @timeframes[params["timeframe"]] ? params["timeframe"] : "2 weeks"

    @daily_usage_sorted = {}
    AwsUsageRecord.where("data_type = ? AND ? < date AND date < ?", 'daily_cost', (Time.now - @timeframes[@selected_timeframe]), Time.now).each do |r|
      @daily_usage[r.account_id] ||= {}
      @daily_usage[r.account_id][r.date] = r.data
    end

    @daily_usage_sorted = {}

    # sort by average spending
    @daily_usage
      .sort_by { |k, v| p (v.values.collect(&:to_i).sum)/v.values.size }
      .reverse
      .each { |i| @daily_usage_sorted[i[0]] = i[1] }


    @daily_usage = @daily_usage_sorted

    to_javascript usage_data: @daily_usage
  end

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
end
