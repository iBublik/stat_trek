require 'stat_trek/errors'
require 'stat_trek/config'
require 'stat_trek/utils'
require 'stat_trek/agg_strategies'
require 'stat_trek/guards'

module StatTrek
  module ClassMethods
    def stat_trek(
      field, key_fields: __default_stat_trek_fields__, agg_strategy: :override,
      stats_model: __default_stat_trek_stats_model__, guards: {}, touch: []
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
      agg_strategy = Utils.build_strategy(agg_strategy, field)

      guards.keys.each do |guard_name|
        unless StatTrek.config.registered_guard?(guard_name)
          raise InvalidMetadataError, "Unknown guard #{guard_name}"
        end
      end

      Array(touch).each do |association|
        next if reflect_on_all_associations.find do |reflection|
          reflection.name == association.to_sym
        end

        raise InvalidMetadataError, "Unknown association #{association}"
      end

      __stat_trek_registry__[field] = Utils::StrictOpenStruct.new(
        key_fields: key_fields, stats_model: stats_model,
        agg_strategy: agg_strategy, guards: Utils.build_guards(
          guards
        ), touch: Array(touch)
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

      keys = context.merge(missing_data)

      triggerd_guards = Array(track_rules.guards).select do |guard|
        guard.call(self, keys)
      end
      return if triggerd_guards.any?

      stats = track_rules.stats_model.find_or_create_by!(keys)

      track_rules.agg_strategy.call(stats, value)

      track_rules.touch.each do |association|
        public_send(association).stat_trek(field, value, context)
      end
    end
  end
end
