module StatTrek
  class RuleBuilder
    REQUIRED_KEY_MAPPING = :__stat_trek_required_key__

    attr_reader :field, :agg_strategy, :guards, :touch, :meta

    def initialize(field:, agg_strategy: :override, guards: {}, touch: [], **meta)
      @field        = field
      @agg_strategy = agg_strategy
      @guards       = guards
      @touch        = touch
      @meta         = meta
    end

    def call(model)
      associations = Array(touch).each do |association|
        next if model.reflect_on_all_associations.find do |reflection|
          reflection.name == association.to_sym
        end

        raise InvalidMetadataError, "Unknown association #{association}"
      end

      Rule.new(
        field:        field,
        key_mapping:  key_mapping_for(model),
        model:        stats_model_for(model),
        strategy:     build_aggregation_strategy,
        guards:       build_guards,
        associations: associations
      )
    end

    private

    def stats_model_for(model)
      meta[:stats_model] || "#{model}Statistic".constantize
    rescue NameError
      raise InvalidMetadataError, "Model to store statistic can not be found"
    end

    def key_mapping_for(model)
      mapping =
        meta[:key_fields] || {
          "#{model.model_name.singular}_id".to_sym => model.primary_key.to_sym
        }

      return mapping if mapping.is_a?(Hash)

      Array(mapping).map do |mapping_or_field|
        if mapping_or_field.is_a?(Hash)
          mapping_or_field
        else
          { mapping_or_field => REQUIRED_KEY_MAPPING }
        end
      end.reduce(:merge)
    end

    def build_aggregation_strategy
      agg_key, options = expand_spec(agg_strategy)
      config = StatTrek.config.agg_strategies.fetch(agg_key) do
        raise InvalidMetadataError, "Unknown aggregation strategy #{agg_key}"
      end

      config.klass.new(
        **config.options, field: field, **options
      )
    end

    def build_guards
      guards.map do |guard_name, options|
        config = StatTrek.config.guards.fetch(guard_name) do
          raise InvalidMetadataError, "Unknown guard #{guard_name}"
        end

        config.klass.new(
          **config.options, field: field, **options
        )
      end
    end

    def expand_spec(spec)
      if spec.is_a?(Symbol)
        [spec, {}]
      else
        spec.first
      end
    end
  end
end
