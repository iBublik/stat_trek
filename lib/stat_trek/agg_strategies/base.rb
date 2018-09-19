module StatTrek
  module AggStrategies
    class Base
      attr_reader :field, :meta

      def initialize(field, meta = {})
        @field = field
        @meta  = meta
      end

      def call(_stats_instance, _value)
        raise NotImplementedError
      end
    end
  end
end
