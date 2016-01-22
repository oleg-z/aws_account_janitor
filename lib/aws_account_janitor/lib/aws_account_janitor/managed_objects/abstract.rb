module AwsAccountJanitor
  class ManagedObjects
    class Abstract
      REQUIRED_TAGS = ["Owner", "Project"]

      attr_reader :account
      def initialize(args = {})
        @account = args[:account]
      end

      def violate_tag_rules?(i)
        binding.pry if i.nil?
        (i[:tags].to_a.collect { |t| t[:key] } & REQUIRED_TAGS).empty?
      end

      def tag_exists?(i, tag)
        !(i[:tags].to_a.detect { |t| t[:key] == tag }.nil?)
      end

      def improperly_tagged
        []
      end

      def underused
        []
      end

      def tags
        []
      end

      def to_hash(o)
        o = (kind_of?(Hash) ? o : o.to_hash).symbolize_keys
      end
    end
  end
end
