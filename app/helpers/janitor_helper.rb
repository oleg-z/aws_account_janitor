module JanitorHelper
  def ddb_link(region, ddb)
    "https://console.aws.amazon.com/dynamodb/home?region=#{region}#table:name=#{ddb["table_name"]}"
  end

  def rds_link(region, id)
    "https://#{region}.console.aws.amazon.com/rds/home?region=#{region}#dbinstances:id=#{id};sf=all"
  end


end
