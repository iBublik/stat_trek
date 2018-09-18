require 'stat_trek/utils'

module StatTrek


  BaseError = Class.new(StandardError)

  class MissingKeyError < BaseError
    def initialize(key)
      super("required key is missing - #{key}")
    end
  end

  class UnknownFieldError < BaseError
    def initialize(field)
      super("unknown stat field given - #{field}")
    end
  end

  module ClassMethods
    def stat_trek(field, key_fields: nil, **args)
      stat_trek_registry[field] = args.reverse_merge(
        stats_model:  "#{self}Statistic".safe_constantize,
        agg_strategy: :override,
        key_fields:   Utils.prepare_key_fields(
          key_fields || { "#{model_name.singular}_id".to_sym => :id }
        )
      )
    end

    def stat_trek_registry
      @__stat_trek_registry__ ||= {}
    end
  end

  module InstanceMethods
    def stat_trek(field, value, context = {})
      track_rules = self.class.stat_trek_registry.fetch(field) do
        raise UnknownFieldError, field
      end

      key_fields   = track_rules.fetch(:key_fields)
      missing_keys = key_fields.reject do |stat_field, _model_field|
        context.include?(stat_field)
      end
      missing_data = missing_keys.map do |stat_field, model_field|
        raise(MissingKeyError, stat_field) unless respond_to?(model_field)

        [stat_field, send(model_field)]
      end.to_h

      stats = track_rules.fetch(:stats_model).find_or_create_by!(
        context.merge(missing_data)
      )
      stats.update!(field => value)
    end
  end
end
