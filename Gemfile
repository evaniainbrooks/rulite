source 'https://rubygems.org'
ruby '2.4.0'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'daemons'
gem 'pg'
gem 'json-schema'
gem 'require_all'
gem 'rest-client'
gem 'rack'
gem 'log4r'
gem 'bitcoin-ruby'
gem 'eventmachine'

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'simplecov'
  gem 'vcr'
  gem 'factory_girl'
end
