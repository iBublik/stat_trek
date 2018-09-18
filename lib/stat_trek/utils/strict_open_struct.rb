module StatTrek
  module Utils
    class StrictOpenStruct
      def initialize(**data)
        @data = data
      end

      def method_missing(method, *args, &block)
        @data.key?(method) ? @data[method] : super
      end

      def respond_to_missing?(method, include_private = false)
        @data.key?(method) || super
      end
    end
  end
end
