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

    ConfigEntry = Struct.new(:klass, :options)

    def initialize
      @agg_strategies = {}
      @guards         = {}

      register_strategy :override, StatTrek::AggStrategies::Override
      register_strategy :sum,      StatTrek::AggStrategies::Sum

      register_guard :time_limit, StatTrek::Guards::TimeLimit
      register_guard :throttle,   StatTrek::Guards::Throttle
    end

    def register_strategy(key, klass, config = {})
      register(@agg_strategies, key, klass, config)
    end

    def register_guard(key, klass, config = {})
      register(@guards, key, klass, config)
    end

    def update_guard(key, config)
      @guards.fetch(key).options.merge!(config)
    end

    def sidekiq=(options)
      Sidekiq.configure_server do |config|
        config.redis = options
      end

      Sidekiq.configure_client do |config|
        config.redis = options
      end
    end

    private

    def register(registry, key, klass, config)
      registry[key] = ConfigEntry.new(klass, config)
    end
  end
end
