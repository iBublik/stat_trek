module StatTrek
  module AggStrategies
    class Base
      attr_reader :field, :meta

      def initialize(field, meta = nil)
        @field = field
        @meta  = meta || default_meta
      end

      def call(_stats_instance, _value)
        raise NotImplementedError
      end

      private

      def default_meta
        {}
      end
    end
  end
end
