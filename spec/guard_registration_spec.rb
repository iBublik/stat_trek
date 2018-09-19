RSpec.describe 'Registration of custom guards' do
  include_context 'test statistic'

  class FancyGuard < StatTrek::Guards::Base
    def triggered?(model_instance, _keys)
      model_instance.fancy?
    end
  end

  before(:all) do
    StatTrek.config.register_guard :fancy, FancyGuard
  end

  with_model :Test do
    model do
      stat_trek :score, guards: { fancy: { on_trigger: :do_some_stuff } }

      def fancy?
        false
      end

      def do_some_stuff
        puts 'Hello world'
      end
    end
  end

  let(:test) { Test.create! }
  let(:stats) { TestStatistic.create!(test_id: test.id, score: 50) }

  context 'guard triggered' do
    before { allow(test).to receive(:fancy?).and_return(true) }

    it 'blocks statistic aggregation' do
      expect { test.stat_trek(:score, 3) }.not_to change { stats.reload.score }
    end

    it 'triggers callback' do
      expect(test).to receive(:do_some_stuff)

      test.stat_trek(:score, 3)
    end
  end

  context "guard isn't triggered" do
    it 'allow stats aggregation' do
      expect { test.stat_trek(:score, 2) }.to change { stats.reload.score }
    end

    it "doesn't trigger callback" do
      expect(test).not_to receive(:do_some_stuff)

      test.stat_trek(:score, 2)
    end
  end
end
