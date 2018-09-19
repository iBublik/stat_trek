RSpec.shared_context 'test statistic' do
  extend WithModel

  with_model :TestStatistic do
    table do |t|
      t.integer :test_id
      t.integer :score

      t.timestamps
    end
  end
end
