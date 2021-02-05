require 'rspec'
require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  # Specify the Chef log_level (default: :warn)
  config.log_level = :warn
end
