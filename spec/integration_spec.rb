RSpec.describe 'Full cycle integration' do
  with_model :TestUserStatistic do
    table do |t|
      t.integer :score
      t.integer :user_id
      t.integer :test_id
    end
  end
  with_model :Test do
    table { |t| t.string :title }

    model do
      has_many :stats, class_name: :TestUserStatistic

      stat_trek :score,
        key_fields:  { user_id: :user_id, test_id: :id },
        stats_model: TestUserStatistic
    end
  end

  let(:user) { User.create!(name: 'John Doe') }
  let(:test) { Test.create!(title: 'Ruby') }

  context 'valid input' do
    let(:deps) { Hash[user_id: user.id] }

    it 'updates statistic' do
      test.stat_trek(:score, 10, deps)
      stats = test.stats.find_by!(deps)

      expect(stats.score).to eq 10
    end

    it "doesn't duplicate stats" do
      test.stats.create!(deps)

      expect { test.stat_trek(:score, 10, deps) }.not_to(
        change(TestUserStatistic, :count)
      )
    end

    it 'can take missing data from model itself' do
      allow(test).to receive(:user_id).and_return(1)

      expect { test.stat_trek(:score, 10) }.to change {
        test.stats.exists?(user_id: 1)
      }.to true
    end
  end

  context 'invalid input' do
    it 'raises error when unknown field given' do
      expect{ test.stat_trek(:wtf, 1) }.to raise_error(
        StatTrek::UnknownFieldError
      )
    end

    it 'raises error when required data is missing' do
      expect{ test.stat_trek(:score, 10) }.to raise_error(
        StatTrek::MissingKeyError
      )
    end
  end
end
