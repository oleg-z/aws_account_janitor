require 'aws-sdk'
require 'open-uri'
require 'pry'


module AwsAccountJanitor
  class Aws
    class Instance
      attr_reader :instance_age
      def initialize(aws_instance)
        @aws_instance = aws_instance
      end

      def to_json

      end
    end
  end
end
