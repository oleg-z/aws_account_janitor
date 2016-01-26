module AwsAccountJanitor
  class Global
     EBS_NAME_MAP = {
      "Amazon EBS General Purpose (SSD) volumes" => "gp2",
      "Amazon EBS Provisioned IOPS (SSD) volumes" => "io1",
      "Amazon EBS Magnetic volumes" =>  "standard"
    }

    def self.ebs_prices(region)
      return @prices if @prices
      prices =
        JSON.parse(
          URI('https://a0.awsstatic.com/pricing/1/ebs/pricing-ebs.min.js')
          .open
          .read
          .gsub(/^[^{]+/, '')
          .gsub(/[^}]+$/, '')
          .gsub(/([\w]+):/, '"\1":')
        )

      @prices = {}
      prices["config"]["regions"]
        .detect { |r| r["region"] == region }["types"]
        .each do |t|
          per_gb = t["values"].detect { |v| v["rate"] == "perGBmoProvStorage" }
          per_iops = t["values"].detect { |v| v["rate"] == "perPIOPSreq" }
          @prices[EBS_NAME_MAP[t["name"]]] = {
            "per_gb" => per_gb.nil? ? 0.0 : per_gb["prices"]["USD"].to_f,
            "per_iops" => per_iops.nil? ? 0.0 : per_iops["prices"]["USD"].to_f
          }
        end
      @prices
    end

    def self.ddb_prices(region)
      return @ddb_prices if @ddb_prices
      prices =
        JSON.parse(
          URI('https://a0.awsstatic.com/pricing/1/dynamodb/pricing-data-throughput.min.js')
          .open
          .read
          .gsub(/^[^{]+/, '')
          .gsub(/[^}]+$/, '')
          .gsub(/([\w]+):/, '"\1":')
        )

      region_price = prices["config"]["regions"].detect { |r| r["region"] == region }

      @ddb_prices = {
        "writes" => region_price["values"]["writes"]["prices"]["USD"].to_f,
        "reads" => region_price["values"]["writes"]["prices"]["USD"].to_f
      }
    end
  end
end
