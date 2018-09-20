RSpec.describe 'Full cycle integration', inline_jobs: true do
  with_model :TestUserStatistic do
    table do |t|
      t.integer :score
      t.integer :user_id
      t.integer :test_id

      t.timestamps
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
  with_model :TestWithUser do
    model do
      has_many :stats, class_name: :TestUserStatistic, foreign_key: :test_id

      stat_trek :score,
        key_fields:  { user_id: :user_id, test_id: :id },
        stats_model: TestUserStatistic

      def user_id
        1
      end
    end
  end

  let(:user) { User.create!(name: 'John Doe') }
  let(:test) { Test.create!(title: 'Ruby') }

  context 'valid input' do
    let(:deps) { Hash[user_id: user.id] }

    it 'updates statistic' do
      test.stat_trek!(:score, 10, deps)
      stats = test.stats.find_by!(deps)

      expect(stats.score).to eq 10
    end

    it "doesn't duplicate stats" do
      test.stats.create!(deps)

      expect { test.stat_trek!(:score, 10, deps) }.not_to(
        change(TestUserStatistic, :count)
      )
    end

    it 'can take missing data from model itself' do
      test_with_user = TestWithUser.create!

      expect { test_with_user.stat_trek!(:score, 10) }.to change {
        test_with_user.stats.exists?(user_id: test_with_user.user_id)
      }.to true
    end
  end

  context 'invalid input' do
    it 'raises error when unknown field given' do
      expect{ test.stat_trek!(:wtf, 1) }.to raise_error(
        StatTrek::UnknownFieldError
      )
    end

    it 'raises error when required data is missing' do
      expect{ test.stat_trek!(:score, 10) }.to raise_error(
        StatTrek::MissingKeyError
      )
    end
  end
end
