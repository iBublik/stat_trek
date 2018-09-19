module StatTrek
  module Guards
    class TimeLimit < Base
      attr_reader :time_field

      def initialize(time_field:, **meta)
        @time_field = time_field
        super(meta)
      end

      private

      def triggered?(model_instance, _key_fields)
        model_instance.public_send(time_field) <= Time.now
      end
    end
  end
end
