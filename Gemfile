source 'https://rubygems.org'

ruby '~> 3.3.0'

# 基本
gem 'rails', '~> 7.2.3'
gem 'pg', '~> 1.5'
gem 'puma', '~> 7.1'

# Asset管理
gem 'sprockets-rails'
gem 'importmap-rails'

# パフォーマンス
gem 'bootsnap', require: false

# 認証
gem 'devise', '~> 4.9'

# ページネーション
gem 'kaminari', '~> 1.2'

# CORS
gem 'rack-cors', '~> 3.0'

group :development, :test do
  gem 'rspec-rails', '~> 8.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :test do
  gem 'simplecov', '~> 0.22', require: false
  gem 'shoulda-matchers', '~> 5.3'
end

group :development do
  gem 'web-console'
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rails', '~> 2.19', require: false
end
