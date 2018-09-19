module StatTrek
  module AggStrategies
    class Override < Base
      def call(stats_instance, value)
        primary_key = stats_instance.class.primary_key

        stats_instance.class
          .where(primary_key => stats_instance[primary_key])
          .update_all(field => value)
      end
    end
  end
end
