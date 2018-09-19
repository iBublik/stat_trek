require 'sidekiq'

require 'stat_trek/errors'
require 'stat_trek/config'
require 'stat_trek/utils'
require 'stat_trek/agg_strategies'
require 'stat_trek/guards'
require 'stat_trek/rule'
require 'stat_trek/worker'

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

      __stat_trek_registry__[field] = Rule.new(
        field: field, key_mapping: key_fields, model: stats_model,
        strategy: agg_strategy, guards: Utils.build_guards(
          guards
        ), associations: Array(touch)
      )
    end

    def rule_for(field)
      __stat_trek_registry__.fetch(field.to_sym) do
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
      stat_trek!(field, value, context)
    rescue MissingKeyError, GuardError
      false
    end

    def stat_trek!(field, value, context = {})
      rule_for(field).compile!(self, context)

      Worker.perform_async(self.class, id, field, value, context)
    end

    def rule_for(field)
      self.class.rule_for(field)
    end
  end
end
