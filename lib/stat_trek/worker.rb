module StatTrek
  class Worker
    include Sidekiq::Worker

    sidekiq_options queue: 'stat_trek'

    def perform(model_klass, model_id, field, value, keys)
      klass = model_klass.constantize

      rule = klass.stat_trek_rule_for(field)

      stats = rule.stats_model.find_or_create_by!(keys)

      rule.agg_strategy.call(stats, value)

      model_instance = klass.find(model_id)

      rule.touch.each do |association|
        Array(model_instance.public_send(association)).each do |instance|
          instance.stat_trek(field, value, keys)
        end
      end
    end
  end
end
