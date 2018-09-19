RSpec.describe 'Default metadata' do
  subject { Test.rule_for(:score) }

  with_model :TestStatistic
  with_model :Test do
    model do
      stat_trek :score
    end
  end

  it 'assigns statistics model' do
    expect(subject.model).to eq TestStatistic
  end

  it 'applies `override` strategy' do
    expect(subject.strategy).to be_a StatTrek::AggStrategies::Override
  end

  it 'creates key field mapping' do
    expect(subject.key_mapping).to eq(test_id: :id)
  end
end
