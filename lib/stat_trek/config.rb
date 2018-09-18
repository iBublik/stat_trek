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
    attr_reader :agg_strategies

    def initialize
      # binding.pry
      @agg_strategies = {
        override:   StatTrek::AggStrategies::Override,
        accumulate: StatTrek::AggStrategies::Accumulate
      }
    end

    def register_strategy(key, klass)
      agg_strategies[key] = klass
    end

    def registered_strategy?(key)
      agg_strategies.include?(key)
    end
  end
end
