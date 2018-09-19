RSpec.describe StatTrek::Guards::Throttle do
  class SimpleBackend
    attr_reader :data

    def initialize
      @data = []
    end

    def store(key, _expiration)
      data << key
    end

    def exists?(key)
      data.include?(key)
    end
  end

  subject do
    described_class.new(
      backend: SimpleBackend.new, field: :score, period: 30.seconds
    )
  end

  with_model :Test

  let(:test) { Test.new }

  it "doesn't trigger when backend is empty" do
    expect(subject.call(test, test_id: 1, user_id: 2)).to be false
  end

  it "triggers when backend contains same data" do
    subject.call(test, test_id: 1, user_id: 2)

    expect(subject.call(test, test_id: 1, user_id: 2)).to be true
  end
end
