source 'https://rubygems.org'

# https://github.com/bundler/bundler/issues/4978
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'fix-db-schema-conflicts'
gem 'pg'
gem 'rails', '~> 5.1.4'

gem 'sass-rails'

gem 'coffee-rails'
gem 'jbuilder'
gem 'jquery-rails'
gem 'turbolinks'
gem 'uglifier', '>= 1.3.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'devise'
gem 'state_machines-activerecord'

gem 'grape'
gem 'grape-entity', github: 'ruby-grape/grape-entity', branch: 'master'

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'guard-livereload'
  gem 'guard-rspec'
  gem 'hirb'
  gem 'pry-byebug'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails'
end

group :test do
  gem 'database_cleaner'
end

group :development do
  gem 'grape_on_rails_routes'
  gem 'letter_opener'
end
