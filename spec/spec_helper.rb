require "bundler/setup"
require "stat_trek"

require 'active_record'
require 'with_model'
require 'pry-byebug'
require 'sidekiq/testing'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3', database: ':memory:'
)

require_relative './support/test_statistic_context'

RSpec.shared_context 'user model' do
  extend WithModel

  with_model :User do
    table { |t| t.string :name }
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.extend WithModel

  config.include_context 'user model'

  config.around(:example, inline_jobs: true) do |example|
    Sidekiq::Testing.inline! { example.run }
  end
end
