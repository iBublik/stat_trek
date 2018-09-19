RSpec.describe StatTrek::Guards::TimeLimit do
  subject { described_class.new(time_field: :deadline) }

  it "doesn't trigger when current time is less than given field value" do
    test = double('Test', deadline: 1.day.from_now)

    expect(subject.call(test, 10)).to be false
  end

  it "triggers when current time is greater than given field value" do
    test = double('Test', deadline: 1.day.ago)

    expect(subject.call(test, 10)).to be true
  end
end
