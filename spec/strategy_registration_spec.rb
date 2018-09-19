RSpec.describe 'Registration of custom strategy' do
  include_context 'test statistic'

  class Double < StatTrek::AggStrategies::Base
    def call(stats_instance, _value)
      stats_instance.class.where(
        id: stats_instance.id
      ).update_all("#{field} = #{field} * 2")
    end
  end

  before(:all) do
    StatTrek.config.register_strategy :double, Double
  end

  with_model :Test do
    model do
      stat_trek :score, agg_strategy: :double
    end
  end

  let(:test) { Test.create! }
  subject { TestStatistic.create!(test_id: test.id, score: 50) }

  it 'changes stats by logic described in registered strategy' do
    expect { test.stat_trek(:score, 10) }.to change { subject.reload.score }
      .to 100
  end
end
