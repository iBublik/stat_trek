require_relative './base'

module StatTrek
  module AggStrategies
    class Override < Base
      def call(stats_instance, value)
        primary_key = stats_instance.class.primary_key

        stats_instance.class
          .where(primary_key => stats_instance[primary_key])
          .where("#{timestamp_field} <= ?", stats_instance[timestamp_field])
          .update_all(field => value)
      end

      private

      def timestamp_field
        meta[:timestamp_field]
      end

      def default_meta
        { timestamp_field: :updated_at }
      end
    end
  end
end
