module StatTrek
  class Worker
    include Sidekiq::Worker

    sidekiq_options queue: 'stat_trek'

    def perform(model_klass, model_id, field, value, context)
      model_instance = model_klass.constantize.find(model_id)

      model_instance.rule_for(field).apply(
        model_instance, value, context
      )
    end
  end
end
