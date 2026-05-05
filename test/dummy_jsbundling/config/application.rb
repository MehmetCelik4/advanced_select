require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"
require "stimulus-rails"
require "turbo-rails"

Bundler.require(*Rails.groups)

module AdvancedSelectJsBundlingDummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.action_controller.include_all_helpers = false
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
