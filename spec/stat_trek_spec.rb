RSpec.describe StatTrek do
  describe 'metadata' do
    subject { Test.stat_trek_registry.fetch(:score) }

    context 'default config' do
      with_model :TestStatistic
      with_model :Test do
        model do
          stat_trek :score
        end
      end

      it 'assigns statistics model' do
        expect(subject[:stats_model]).to eq TestStatistic
      end

      it 'uses `override` agg strategy' do
        expect(subject[:agg_strategy]).to eq :override
      end

      it 'defines key fields' do
        expect(subject[:key_fields]).to eq(test_id: :id)
      end
    end

    context 'overrides' do
      with_model :CustomTestStats
      with_model :Test do
        model do
          stat_trek :score,
            stats_model:  CustomTestStats,
            agg_strategy: :accumulate,
            key_fields:   { user_id: :column1, test_id: :column2 }
        end
      end

      it 'allows to pass config options' do
        expect(subject).to eq(
          stats_model:  CustomTestStats,
          agg_strategy: :accumulate,
          key_fields:   { user_id: :column1, test_id: :column2 }
        )
      end
    end
  end
end
