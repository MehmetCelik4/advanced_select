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

  test "selects and deselects multiple local options" do
    visit root_path

    find("#example_multiple_ids_trigger").click
    find("#example_multiple_ids_options button", text: "Multi One").click
    find("#example_multiple_ids_options button", text: "Multi Two").click

    assert_selector "input[name='example[multiple_ids][]'][value='multi-1']", visible: false
    assert_selector "input[name='example[multiple_ids][]'][value='multi-2']", visible: false
    assert_selector "#example_multiple_ids_summary", text: "Multi One"
    assert_selector "#example_multiple_ids_summary", text: "Multi Two"

    find("#example_multiple_ids_options button", text: "Multi One").click

    assert_no_selector "input[name='example[multiple_ids][]'][value='multi-1']", visible: false
    assert_selector "input[name='example[multiple_ids][]'][value='multi-2']", visible: false
    assert_no_selector "#example_multiple_ids_summary", text: "Multi One"
    assert_selector "#example_multiple_ids_summary", text: "Multi Two"
  end

  test "keeps option identity separate from submit value and uses display labels" do
    visit root_path

    find("#example_submit_id_trigger").click
    find("#example_submit_id_options button", text: "Hierarchy > Submit Item").click

    assert_selector "input[name='example[submit_id]'][value='submit-7']", visible: false
    assert_selector "#example_submit_id_summary", text: "Submit Item"
    assert_no_selector "#example_submit_id_summary", text: "Hierarchy > Submit Item"

    find("#example_submit_id_trigger").click
    assert_selector "#example_submit_id_options button[aria-selected='true'][data-advanced-select-value-param='identity-7'][data-advanced-select-submit-value-param='submit-7']", text: "Hierarchy > Submit Item"
  end

  test "selects options rendered with a custom option content partial" do
    visit root_path

    find("#example_product_id_trigger").click

    assert_selector "#example_product_id_options .custom-product-code", text: "P-001"

    find("#example_product_id_options button", text: "Product One").click

    assert_selector "input[name='example[product_id]'][value='product-1']", visible: false
    assert_selector "#example_product_id_summary", text: "Product One"
  end

  test "sends dependent field values with remote option requests" do
    visit root_path

    select "South", from: "example_dependency"
    find("#example_dependent_id_trigger").click

    assert_selector "#example_dependent_id_options button", text: "Dependent South"
  end

  test "renders remote error state when option loading fails" do
    visit root_path

    find("#example_error_id_trigger").click

    assert_selector "#example_error_id_options .ui-advanced-select-error", text: "Options could not be loaded"
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

    find("#example_styled_remote_id_options button", text: "Add Brand New").click
    assert_selector "input[name='example[styled_remote_id]'][value='__new__:Brand New']", visible: false
    assert_selector "#example_styled_remote_id_summary", text: "Brand New"
  end
end
