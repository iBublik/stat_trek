require 'redis'

module StatTrek
  module Guards
    class Throttle < Base
      attr_reader :backend, :period

      class RedisBackend
        attr_reader :storage

        KEY_PREFIX = 'stat_trek'.freeze

        def initialize(options)
          @storage = Redis.new(options)
        end

        def store(key, expiration)
          storage.setex(
            full_key(key), expiration, true
          )
        end

        def exists?(key)
          storage.exists(
            full_key(key)
          )
        end

        private

        def full_key(key)
          "#{KEY_PREFIX}:#{key}"
        end
      end

      def initialize(backend: {}, period:, **meta)
        @period  = period
        @backend =
          if backend.is_a?(Hash)
            RedisBackend.new(backend)
          else
            backend
          end

        super(meta)
      end

      def call(model_instance, key_fields)
        result = super
        unless result
          backend.store(
            compute_key(key_fields), period
          )
        end
        result
      end

      private

      def triggered?(model_instance, key_fields)
        backend.exists?(
          compute_key(key_fields)
        )
      end

      def compute_key(key_fields)
        [
          *meta.values_at(:stats_model, :field),
          key_fields.reduce('') do |(key_name, key_value), result|
            result << "#{key_name}_#{key_value}"
          end
        ].join('_')
      end
    end
  end
end
