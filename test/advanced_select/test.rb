require "test_helper"

class AdvancedSelectTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert AdvancedSelect::VERSION
  end

  test "it exposes the importmap controller asset through the engine" do
    assert_includes Rails.application.config.assets.paths.map(&:to_s), AdvancedSelect::Engine.root.join("app/javascript").to_s
    assert_includes Rails.application.config.assets.precompile, "advanced_select/advanced_select_controller.js"
  end
end
