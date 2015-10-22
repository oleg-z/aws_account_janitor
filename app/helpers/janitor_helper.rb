module JanitorHelper
  def ddb_link(region, ddb)
    "https://console.aws.amazon.com/dynamodb/home?region=#{region}#table:name=#{ddb["table_name"]}"
  end
end
