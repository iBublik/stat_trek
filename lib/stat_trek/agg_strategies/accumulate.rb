module StatTrek
  module AggStrategies
    class Accumulate < Base
      def call(stats_instance, value)
        stats_instance.class.update_counters(
          stats_instance.id, field => value
        )
      end
    end
  end
end
