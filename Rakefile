require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :db_prepare do
  Dir.chdir("test/dummy_app") do
    #FileUtils.rm(::Dir.glob("spec/dummy_app/db/*.sqlite3"))
    
    system("bundle exec rake db:drop RAILS_ENV=test")
    system("bundle exec rake db:create RAILS_ENF=test")
  end
end

task default: [:db_prepare, :test]

task :console do
  require 'active_record'

  require_relative 'migration.rb'

  require 'irb'
  binding.irb
end
