source 'https://rubygems.org'

ruby '~> 3.3.0'

# 基本
gem 'pg', '~> 1.5'
gem 'puma', '~> 7.1'
gem 'rails', '~> 7.2.3'

# Asset管理
gem 'importmap-rails'
gem 'sprockets-rails'

# パフォーマンス
gem 'bootsnap', require: false

# 認証
gem 'devise', '~> 4.9'

# ページネーション
gem 'kaminari', '~> 1.2'

# JSON API
gem 'jbuilder', '~> 2.12'

# CORS
gem 'rack-cors', '~> 3.0'

group :development, :test do
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 8.0'
end

group :test do
  gem 'shoulda-matchers', '~> 7.0'
  gem 'simplecov', '~> 0.22', require: false
end

group :development do
  gem 'annotate'
  gem 'brakeman', require: false
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rails', '~> 2.19', require: false
  gem 'rubocop-rspec', require: false
  gem 'web-console'
end
