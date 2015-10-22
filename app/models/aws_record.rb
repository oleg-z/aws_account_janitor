class AwsRecord < ActiveRecord::Base
  serialize :data, JSON
end
