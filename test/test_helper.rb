#$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
ENV["RAILS_ENV"] = "test"

begin
  require 'warning'

  Warning.ignore(
    %r{mail/parsers/address_lists_parser}, ### Hide mail gem warnings
  )
rescue LoadError
  # Do nothing
end

### Instantiates Rails
require File.expand_path("../dummy_app/config/environment.rb",  __FILE__)

require "rails/test_help"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

Rails.backtrace_cleaner.remove_silencers!

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::DefaultReporter.new,
  ENV,
  Minitest.backtrace_filter
)

require "minitest/autorun"

# Run any available migration
if ActiveRecord.gem_version >= Gem::Version.new("6.0")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__), ActiveRecord::SchemaMigration).migrate
elsif ActiveRecord.gem_version >= Gem::Version.new("5.2")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
else
  ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)
end

### LOAD ALL MODELS for `.subclasses` method
Dir.glob(Rails.root.join("app/models/*.rb")).each{|f| require(f) }   

klasses = ApplicationRecord.subclasses + [PostPosts]

klasses.each do |klass|
  if defined?(SQLite3)
    ActiveRecord::Base.connection.execute("DELETE FROM #{klass.table_name};")
    ActiveRecord::Base.connection.execute("UPDATE `sqlite_sequence` SET `seq` = 0 WHERE `name` = '#{klass.table_name}';")
  else
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{klass.table_name}")
  end
end

DATA = {}.with_indifferent_access
