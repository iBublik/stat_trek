require 'sidekiq'

require 'stat_trek/errors'
require 'stat_trek/config'
require 'stat_trek/agg_strategies'
require 'stat_trek/guards'
require 'stat_trek/rule_builder'
require 'stat_trek/rule'
require 'stat_trek/worker'

module StatTrek
  module ClassMethods
    def stat_trek(field, **args)
      __stat_trek_registry__[field] = RuleBuilder.new(
        field: field, **args
      ).call(self)
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
