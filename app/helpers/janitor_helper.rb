module JanitorHelper
  def ddb_link(region, ddb)
    "https://console.aws.amazon.com/dynamodb/home?region=#{region}#tables:selected=#{ddb["table_name"]}"
  end

  def rds_link(region, id)
    "https://#{region}.console.aws.amazon.com/rds/home?region=#{region}#dbinstances:id=#{id};sf=all"
  end

  def format_time(string)
    Time.parse(string).strftime("%m/%d/%Y")
  end

  def update_url(new_params)
    merged_params = params
    merged_params.merge!(new_params)
    merged_params[:action] = action_name
    url_for(merged_params)
  end
end
