require 'stat_trek/agg_strategies/accumulate'

RSpec.describe StatTrek::AggStrategies::Accumulate do
  with_model :Statistic do
    table do |t|
      t.integer :score
    end
  end

  let!(:stats) { Statistic.create!(score: 10) }
  subject { described_class.new(:score) }

  it 'adds new value to existing value' do
    expect { subject.call(stats, 20) }.to change { stats.reload.score }.to 30
  end
end
