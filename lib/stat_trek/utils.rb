require 'stat_trek/utils/strict_open_struct'

module StatTrek
  module Utils
    KEY_WITHOUT_MAPPING = :__stat_trek_missing_key__

    class << self
      def prepare_key_fields(fields)
        return fields if fields.is_a?(Hash)

        Array(fields).map do |mapping_or_field|
          if mapping_or_field.is_a?(Hash)
            mapping_or_field
          else
            { mapping_or_field => KEY_WITHOUT_MAPPING }
          end
        end.reduce(:merge)
      end

      def initialize_strategy(opts, field)
        key, options =
          if opts.is_a?(Symbol)
            [opts, nil]
          else
            opts.first
          end

        klass = StatTrek.config.agg_strategies.fetch(key)
        klass.new(field, options)
      end
    end
  end
end
