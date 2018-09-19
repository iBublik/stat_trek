RSpec.describe StatTrek::AggStrategies::Override do
  with_model :Statistic do
    table do |t|
      t.integer :score

      t.timestamps
    end
  end

  let(:stats) { Statistic.create!(score: 10) }
  subject     { described_class.new(field: :score) }

  it 'overrides existing value' do
    expect { subject.call(stats, 20) }.to change { stats.reload.score }.to 20
  end
end
