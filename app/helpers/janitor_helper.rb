module JanitorHelper
  # Returns true if an asset exists in the Asset Pipeline, false if not.
  def asset_exists?(path)
    begin
      pathname = Rails.application.assets.resolve(path)
      return !!pathname # double-bang turns String into boolean
    rescue Sprockets::FileNotFound
      return false
    end
  end

  def ddb_link(region, id)
    "https://console.aws.amazon.com/dynamodb/home?region=#{region}#tables:selected=#{id}"
  end

  def rds_link(region, id)
    "https://#{region}.console.aws.amazon.com/rds/home?region=#{region}#dbinstances:id=#{id};sf=all"
  end

  def ec2_instance_link(region, ids)
    ids = [ids] unless ids.kind_of?(Array)
    "https://console.aws.amazon.com/ec2/v2/home?region=#{region}#Instances:search=#{ids.join(",")}"
  end

  def ec2_volume_link(region, ids)
    ids = [ids] unless ids.kind_of?(Array)
    "https://console.aws.amazon.com/ec2/v2/home?region=#{region}#Volumes:search=#{ids.join(",")}"
  end

  def ec2_snapshot_link(region, id)
    "https://console.aws.amazon.com/ec2/v2/home?region=#{region}#Snapshots:visibility=owned-by-me;search=#{id}"
  end

  def format_time(string)
    Time.parse(string).strftime("%m/%d/%Y")
  end

  def sort_tags(tags)
    return [] if tags.nil?
    tags.select { |t| ["Name", "Owner", "Project"].include?(t["key"]) } + tags.reject { |t| ["Name", "Owner", "Project"].include?(t["key"]) }.sort_by { |t| t["key"]}
  end

  def update_url(new_params)
    merged_params = params
    merged_params.merge!(new_params)
    merged_params[:action] = action_name
    url_for(merged_params)
  end

  def page_label
    @object_type.name.split("::").last.capitalize
  end
end
