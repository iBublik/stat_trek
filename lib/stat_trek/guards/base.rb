module StatTrek
  module Guards
    class Base
      DEFAULT_ON_TRIGGER_CALLBACK = Proc.new

      attr_reader :meta, :on_trigger_callback

      def initialize(on_trigger: DEFAULT_ON_TRIGGER_CALLBACK, **meta)
        @on_trigger_callback = on_trigger
        @meta                = meta
      end

      def call(model_instance, key_fields)
        if triggered?(model_instance, key_fields)
          on_trigger(model_instance)

          raise GuardError
        end
      end

      def after_skip(_model_instance, _key_fields)
      end

      private

      def triggered?(_model_instance, _value)
        raise NotImplementedError
      end

      def on_trigger(model_instance)
        if on_trigger_callback.is_a?(Proc)
          on_trigger_callback.call(model_instance)
        else
          model_instance.public_send(on_trigger_callback)
        end
      end
    end
  end
end
