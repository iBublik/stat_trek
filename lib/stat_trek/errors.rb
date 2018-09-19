module StatTrek
  BaseError = Class.new(StandardError)

  InvalidMetadataError = Class.new(BaseError)

  class MissingKeyError < BaseError
    def initialize(key)
      super("Required key is missing - #{key}")
    end
  end

  class UnknownFieldError < BaseError
    def initialize(field)
      super("Unknown statistics field given - #{field}")
    end
  end
end
