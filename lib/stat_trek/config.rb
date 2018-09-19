module StatTrek
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end
  end

  class Configuration
    attr_reader :agg_strategies, :guards

    GuardConfig = Struct.new(:klass, :options) do
      def initialize(klass, options = {})
        super
      end
    end

    def initialize
      @agg_strategies = {
        override:   StatTrek::AggStrategies::Override,
        accumulate: StatTrek::AggStrategies::Accumulate
      }

      @guards = {
        time_limit: GuardConfig.new(StatTrek::Guards::TimeLimit),
        throttle:   GuardConfig.new(StatTrek::Guards::TimeLimit)
      }
    end

    def register_strategy(key, klass)
      agg_strategies[key] = klass
    end

    def registered_strategy?(key)
      agg_strategies.include?(key)
    end

    def register_guard(key, klass, config = {})
      guards[key] = GuardConfig.new(klass, config)
    end

    def configure_guard(key, config)
      guards.fetch(key).options = config
    end

    def registered_guard?(key)
      guards.include?(key)
    end
  end
end
