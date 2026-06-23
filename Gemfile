source "https://rubygems.org"

ruby "3.4.3"

gem "rails", "~> 7.2.2"
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"

gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

gem "rack-cors"

# Swagger / OpenAPI
gem "rswag-api", "~> 2.13"
gem "rswag-ui", "~> 2.13"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "rswag-specs", "~> 2.13"
end
