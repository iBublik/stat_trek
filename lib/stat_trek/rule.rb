module StatTrek
  class Rule
    attr_reader :field, :key_mapping, :model, :strategy, :guards, :associations

    def initialize(field:, key_mapping:, model:, strategy:, guards:, associations:)
      @field        = field
      @key_mapping  = key_mapping
      @model        = model
      @strategy     = strategy
      @guards       = guards
      @associations = associations
    end

    def compile!(model_instance, context)
      context = context.symbolize_keys
      keys    = prepare_keys!(model_instance, context)

      guards.each do |guard|
        guard.call(model_instance, keys)
      end.each do |guard|
        guard.after_skip(model_instance, keys)
      end
    end

    def apply(model_instance, value, context)
      context = context.symbolize_keys
      keys    = prepare_keys!(model_instance, context)

      stats = model.find_or_create_by!(keys)
      strategy.call(stats, value)

      associations.each do |association|
        Array(model_instance.public_send(association)).each do |instance|
          instance.stat_trek(field, value, context)
        end
      end
    end

    private

    def prepare_keys!(model_instance, context)
      missing_keys = key_mapping.reject do |stat_field, _model_field|
        context.include?(stat_field)
      end
      missing_data = missing_keys.map do |stat_field, model_field|
        raise(MissingKeyError, stat_field) unless model_instance.respond_to?(model_field)

        [stat_field, model_instance.send(model_field)]
      end.to_h

      context.slice(*key_mapping.keys).merge(missing_data)
    end
  end
end
