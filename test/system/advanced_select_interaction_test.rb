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

  test "applies host class map to active add and selected states" do
    visit root_path

    assert_selector "#example_styled_id_trigger.ui-advanced-select-trigger.test-trigger-class"

    find("#example_styled_id_trigger").click
    assert_selector "#example_styled_id_options button.test-option-class.test-option-selected-class[data-advanced-select-option]", text: "Styled One"
    assert_no_selector "#example_styled_id_options button.ui-advanced-select-option", text: "Styled One"

    find("#example_styled_id_options button", text: "Styled Two").hover
    assert_selector "#example_styled_id_options button.test-option-active-class.test-option-active-extra", text: "Styled Two"
    assert_no_selector "#example_styled_id_options button.ui-advanced-select-option-active", text: "Styled Two"
    assert_no_selector "#example_styled_id_options button.test-option-active-class", text: "Styled One"

    find("#example_styled_id_options button", text: "Styled Two").click
    find("#example_styled_id_trigger").click

    assert_selector "#example_styled_id_options button.test-option-selected-class", text: "Styled Two"
    assert_no_selector "#example_styled_id_options button.test-option-selected-class", text: "Styled One"
    find("#example_styled_id_trigger").send_keys(:escape)

    find("#example_styled_remote_id_trigger").click
    fill_in "example_styled_remote_id_search", with: "Brand New"

    assert_selector "#example_styled_remote_id_options button.test-add-option-class[data-advanced-select-add-option]", text: "Add Brand New"
    assert_no_selector "#example_styled_remote_id_options button.ui-advanced-select-add-option", text: "Add Brand New"

    find("#example_styled_remote_id_options button", text: "Add Brand New").hover
    assert_selector "#example_styled_remote_id_options button.test-option-active-class.test-add-option-active-class", text: "Add Brand New"
    assert_no_selector "#example_styled_remote_id_options button.ui-advanced-select-option-active", text: "Add Brand New"
  end
end
