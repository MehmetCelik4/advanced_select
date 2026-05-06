require "application_system_test_case"

class AdvancedSelectInteractionTest < ApplicationSystemTestCase
  test "loads default stylesheet through the asset pipeline" do
    visit root_path

    assert_selector "link[rel='stylesheet'][href*='advanced_select/advanced_select']", visible: false
    assert_selector "link[rel='stylesheet'][href*='advanced_select_overrides']", visible: false
    assert_equal "flex", page.evaluate_script("getComputedStyle(document.querySelector('#example_item_id_trigger')).display")
    assert_equal "3px", page.evaluate_script("getComputedStyle(document.querySelector('#example_item_id_trigger')).borderTopWidth")
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('#example_item_id_dropdown')).display")
  end

  test "selects local options and remote Turbo Stream options" do
    visit root_path

    find("#example_item_id_trigger").click
    find("#example_item_id_options button", text: "Local One").click

    assert_selector "input[name='example[item_id]'][value='local-1']", visible: false
    assert_selector "#example_item_id_summary", text: "Local One"

    find("#example_remote_id_trigger").click
    fill_in "example_remote_id_search", with: "Beta"

    assert_selector "#example_remote_id_options button", text: "Remote Beta"

    find("#example_remote_id_options button", text: "Remote Beta").click

    assert_selector "input[name='example[remote_id]'][value='remote-2']", visible: false
    assert_selector "#example_remote_id_summary", text: "Remote Beta"
  end
end
