require 'logger'

module AwsAccountJanitor
  class Logger
    def self.get
      @logger ||= ::Logger.new(STDOUT)
      return @logger
    end

    def self.set(logger)
      @logger = logger
    end
  end
end
