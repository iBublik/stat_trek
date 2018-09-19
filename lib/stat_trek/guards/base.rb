module StatTrek
  module Guards
    class Base
      attr_reader :meta, :on_trigger_callback

      def initialize(on_trigger: proc {}, **meta)
        @on_trigger_callback = on_trigger
        @meta                = meta
      end

      def call(model_instance, key_fields)
        is_triggered = triggered?(model_instance, key_fields)

        on_trigger(model_instance) if is_triggered

        is_triggered
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