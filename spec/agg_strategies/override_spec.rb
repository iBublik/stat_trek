require 'stat_trek/agg_strategies/override'

RSpec.describe StatTrek::AggStrategies::Override do
  with_model :Statistic do
    table do |t|
      t.integer :score

      t.timestamps
    end
  end

  let!(:stats) { Statistic.create!(score: 10) }
  subject { described_class.new(:score) }

  it 'overrides existing value' do
    expect { subject.call(stats, 20) }.to change { stats.reload.score }.to 20
  end

  it "doesn't override value when it's outdated" do
    outdated_stats = Statistic.find(stats.id)
    Statistic.where(id: stats.id).update_all(
      updated_at: stats.updated_at + 1.hour
    )

    expect { subject.call(outdated_stats, 20) }.not_to change {
      stats.reload.score
    }
  end
end
