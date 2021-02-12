source "https://rubygems.org"

#gemspec

gem "rake"
gem "minitest"
gem 'minitest-reporters'

if RUBY_VERSION.to_f >= 2.4
  gem 'warning'
end

if (RUBY_VERSION.to_f < 2.5 || false) ### set to true if locally testing old Rails version
  #gem 'rails', '~> 5.0.7'
  #gem 'rails', '~> 5.1.7'
  gem 'rails', "~> 5.2.4"
else
  #gem 'rails', '~> 6.0.3'
  #gem 'rails', '~> 6.1.1'
  gem 'rails'
end

gem 'pg' ### SQLite doesnt support changing tables so cant use same technique provided here - https://www.sqlite.org/lang_altertable.html
