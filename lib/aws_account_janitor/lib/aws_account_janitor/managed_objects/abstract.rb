module AwsAccountJanitor
  class ManagedObjects
    class Abstract
      attr_reader :account
      def initialize(args = {})
        @account = args[:account]
      end

      def tag_exists?(i, tag)
        !(i.tags.detect { |t| t.key == tag }.nil?)
      end
    end
  end
end
