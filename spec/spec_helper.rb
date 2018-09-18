require "bundler/setup"
require "stat_trek"

require 'active_record'
require 'with_model'
require 'pry-byebug'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3', database: ':memory:'
)

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
end
