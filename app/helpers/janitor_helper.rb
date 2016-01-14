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


end
