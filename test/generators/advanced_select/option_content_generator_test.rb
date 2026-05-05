require "test_helper"
require "rails/generators/test_case"
require "generators/advanced_select/option_content/option_content_generator"

class AdvancedSelectOptionContentGeneratorTest < Rails::Generators::TestCase
  tests AdvancedSelect::Generators::OptionContentGenerator
  destination File.expand_path("../../../tmp/generators/option_content", __dir__)
  setup :prepare_destination

  test "creates a named option content partial" do
    run_generator ["product"]

    assert_file "app/views/advanced_select/option_contents/_product.html.erb" do |content|
      assert_includes content, "locals: (option:)"
      assert_includes content, "option.fetch(:label)"
    end
  end
end
