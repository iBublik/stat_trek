module StatTrek
  module AggStrategies
    class Override < Base
      def call(stats_instance, value)
        stats_instance.update!(field => value)
      end
    end
  end
end
