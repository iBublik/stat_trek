RSpec.describe 'Chaining of statistics tracking', inline_jobs: true do
  with_model :CourseStats do
    table do |t|
      t.integer :score
      t.integer :course_id
      t.integer :user_id

      t.timestamps
    end
  end

  with_model :Course do
    model do
      stat_trek :score, key_fields: [:user_id, course_id: :id], stats_model: CourseStats
    end
  end

  with_model :TestStats do
    table do |t|
      t.integer :score
      t.integer :test_id
      t.integer :user_id

      t.timestamps
    end
  end

  with_model :Test do
    table do |t|
      t.integer :course_id
    end

    model do
      belongs_to :course

      stat_trek :score, key_fields: [:user_id, test_id: :id], stats_model: TestStats,
        touch: :course
    end
  end

  let(:course) { Course.create! }
  let(:test)   { Test.create!(course: course) }
  let(:attrs)  { Hash[user_id: 1] }

  it 'updates stats for specified association' do
    test.stat_trek(:score, 20, attrs)
    course_stats = CourseStats.find_by!(**attrs, course_id: course.id)

    expect(course_stats.score).to eq 20
  end
end
