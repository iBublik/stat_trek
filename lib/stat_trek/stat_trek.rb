require 'stat_trek/config'
require 'stat_trek/utils'
require 'stat_trek/utils/strict_open_struct'

require 'stat_trek/agg_strategies/base'

module StatTrek
  BaseError = Class.new(StandardError)

  InvalidMetadataError = Class.new(BaseError)

  class MissingKeyError < BaseError
    def initialize(key)
      super("Required key is missing - #{key}")
    end
  end

  class UnknownFieldError < BaseError
    def initialize(field)
      super("Unknown statistics field given - #{field}")
    end
  end

  module ClassMethods
    def stat_trek(
      field, key_fields: __default_stat_trek_fields__, agg_strategy: :override,
      stats_model: __default_stat_trek_stats_model__
    )
      key_fields = Utils.prepare_key_fields(
        key_fields
      )

      if stats_model.nil?
        raise InvalidMetadataError, "Model to store statistic is not given"
      end

      unless StatTrek.config.registered_strategy?(agg_strategy)
        raise InvalidMetadataError, "Unknown strategy #{agg_strategy}"
      end
      agg_strategy = Utils.initialize_strategy(agg_strategy, field)

      __stat_trek_registry__[field] = Utils::StrictOpenStruct.new(
        key_fields: key_fields, stats_model: stats_model,
        agg_strategy: agg_strategy
      )
    end

    def stat_trek_rule_for(field)
      __stat_trek_registry__.fetch(field) do
        raise UnknownFieldError, field
      end
    end

    private

    def __stat_trek_registry__
      @__stat_trek_registry__ ||= {}
    end

    def __default_stat_trek_fields__
      { "#{model_name.singular}_id".to_sym => :id }
    end

    def __default_stat_trek_stats_model__
      "#{self}Statistic".safe_constantize
    end
  end

  module InstanceMethods
    def stat_trek(field, value, context = {})
      track_rules = self.class.stat_trek_rule_for(field)

      key_fields   = track_rules.key_fields
      missing_keys = key_fields.reject do |stat_field, _model_field|
        context.include?(stat_field)
      end
      missing_data = missing_keys.map do |stat_field, model_field|
        raise(MissingKeyError, stat_field) unless respond_to?(model_field)

        [stat_field, send(model_field)]
      end.to_h

      stats = track_rules.stats_model.find_or_create_by!(
        context.merge(missing_data)
      )

      track_rules.agg_strategy.call(stats, value)

      # stats.update!(field => value)
    end
  end
end
