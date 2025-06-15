# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.3'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.0'

gem 'propshaft', '~> 1.1'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.5'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 6.3'

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
# gem 'jsbundling-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails', '~> 2.0'
#
# # Bundle and process CSS [https://github.com/rails/cssbundling-rails]
# gem 'cssbundling-rails'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5.4'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', '~> 1.9.1', platforms: %i[mri mingw x64_mingw]

  gem 'dotenv-rails', '~> 3'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 8'

  gem 'ruby-lsp'
  gem 'solargraph'
  gem 'solargraph-rspec'
end

group :development do
  gem 'annotaterb', '~> 4.14.0'

  gem 'erb_lint', '~> 0.9'

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  gem 'rubocop', '~> 1.75'
  gem 'rubocop-performance', '~> 1'
  gem 'rubocop-rails', '~> 2'
  gem 'rubocop-rspec', '~> 3'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'

  gem 'shoulda-matchers'
end

gem 'ahoy_matey', '~> 5.0'
gem 'amazing_print', require: 'ap'
gem 'avo', '~> 3.20'
gem 'blazer', '~> 3.3'
gem 'derived_images', '~> 0.4.1'
gem 'execjs', '~> 2.10'
gem 'flipper', '~> 1.3.4'
gem 'flipper-ui', '~> 1.3.4'
gem 'http', '~> 5.2'
gem 'mini_racer', '~> 0.18'
gem 'request_store', '~> 1.7'
gem 'view_component', '~> 3.22'

gem 'tailwindcss-ruby', '~> 4.1'

gem 'tailwindcss-rails', '~> 4.2'

gem 'flipper-active_record', '~> 1.3'
