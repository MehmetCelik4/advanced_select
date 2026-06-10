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
    assert_field "example_item_id_search", placeholder: "Search..."
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

  test "filters local options on the client" do
    visit root_path

    find("#example_item_id_trigger").click
    fill_in "example_item_id_search", with: "Two"

    assert_selector "#example_item_id_options button", text: "Local Two"
    assert_no_selector "#example_item_id_options button", text: "Local One"

    fill_in "example_item_id_search", with: "Missing"

    assert_selector "#example_item_id_options .ui-advanced-select-empty", text: "No options found"
  end

  test "keeps remote multiple selected ticks after turbo stream replacements" do
    visit root_path

    find("#example_remote_multiple_ids_trigger").click

    assert_selector "input[name='example[remote_multiple_ids][]'][value='']", visible: false
    assert_selected_option_check "example_remote_multiple_ids", "Remote Alpha"
    assert_selected_option_check "example_remote_multiple_ids", "Remote Beta"
    assert_selected_option_check "example_remote_multiple_ids", "Remote Gamma"

    find("#example_remote_multiple_ids_options button", text: "Remote Delta").click

    assert_selector "input[name='example[remote_multiple_ids][]'][value='remote-1']", visible: false
    assert_selector "input[name='example[remote_multiple_ids][]'][value='remote-2']", visible: false
    assert_selector "input[name='example[remote_multiple_ids][]'][value='remote-3']", visible: false
    assert_selector "input[name='example[remote_multiple_ids][]'][value='remote-4']", visible: false
    assert_selector "#example_remote_multiple_ids_summary", text: "& +2"

    assert_selector "#example_remote_multiple_ids_options button:first-child[data-advanced-select-value-param='remote-4']"
    assert_selected_option_check "example_remote_multiple_ids", "Remote Alpha"
    assert_selected_option_check "example_remote_multiple_ids", "Remote Beta"
    assert_selected_option_check "example_remote_multiple_ids", "Remote Gamma"
    assert_selected_option_check "example_remote_multiple_ids", "Remote Delta"
  end

  test "selects and deselects multiple local options" do
    visit root_path

    assert_selector "input[name='example[multiple_ids][]'][value='']", visible: false

    find("#example_multiple_ids_trigger").click
    find("#example_multiple_ids_options button", text: "Multi One").click
    find("#example_multiple_ids_options button", text: "Multi Two").click

    assert_selector "#example_multiple_ids_options button:first-child[data-advanced-select-value-param='multi-2']"
    assert_selector "input[name='example[multiple_ids][]'][value='multi-1']", visible: false
    assert_selector "input[name='example[multiple_ids][]'][value='multi-2']", visible: false
    assert_selector "#example_multiple_ids_summary", text: "Multi One"
    assert_selector "#example_multiple_ids_summary", text: "Multi Two"

    find("#example_multiple_ids_options button", text: "Multi One").click

    assert_no_selector "input[name='example[multiple_ids][]'][value='multi-1']", visible: false
    assert_selector "input[name='example[multiple_ids][]'][value='multi-2']", visible: false
    assert_no_selector "#example_multiple_ids_summary", text: "Multi One"
    assert_selector "#example_multiple_ids_summary", text: "Multi Two"

    find("#example_multiple_ids_options button", text: "Multi Two").click

    assert_selector "input[name='example[multiple_ids][]'][value='']", visible: false
    assert_no_selector "input[name='example[multiple_ids][]'][value='multi-2']", visible: false
  end

  test "omits the hidden blank field when include_hidden is false" do
    visit root_path

    assert_no_selector "input[name='example[multiple_ids_without_blank][]'][value='']", visible: false

    find("#example_multiple_ids_without_blank_trigger").click
    find("#example_multiple_ids_without_blank_options button", text: "Multi One").click

    assert_selector "input[name='example[multiple_ids_without_blank][]'][value='multi-1']", visible: false
    assert_no_selector "input[name='example[multiple_ids_without_blank][]'][value='']", visible: false

    find("#example_multiple_ids_without_blank_options button", text: "Multi One").click

    assert_no_selector "input[name='example[multiple_ids_without_blank][]'][value='multi-1']", visible: false
    assert_no_selector "input[name='example[multiple_ids_without_blank][]'][value='']", visible: false
  end

  test "moves newly selected multiple options to the top of local and remote lists" do
    visit root_path

    find("#example_multiple_ids_trigger").click
    find("#example_multiple_ids_options button", text: "Multi One").click
    find("#example_multiple_ids_options button", text: "Multi Two").click

    assert_first_option_value "example_multiple_ids", "multi-2"

    find("#example_remote_multiple_ids_trigger").click
    find("#example_remote_multiple_ids_options button", text: "Remote Delta").click

    assert_first_option_value "example_remote_multiple_ids", "remote-4"
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

  test "eagerly loads and auto-selects dependent options without opening" do
    visit root_path

    assert_selector "#example_eager_dependent_id_summary", text: "Dependent North"
    assert_selector "input[name='example[eager_dependent_id]'][value='dependent-north']", visible: false

    select "South", from: "example_eager_dependency"

    assert_selector "#example_eager_dependent_id_summary", text: "Dependent South"
    assert_selector "input[name='example[eager_dependent_id]'][value='dependent-south']", visible: false
  end

  test "does not eagerly load dependent options when eager is disabled" do
    visit root_path

    select "South", from: "example_eager_dependency"

    assert_selector "#example_lazy_dependent_id_summary", text: "Lazy dependent item"
    assert_empty find("input[name='example[lazy_dependent_id]']", visible: false).value
  end

  test "propagates an advanced select selection to eager dependent options" do
    visit root_path

    find("#example_chain_parent_trigger").click
    find("#example_chain_parent_options button", text: "South").click

    assert_selector "#example_chain_dependent_id_summary", text: "Dependent South"
    assert_selector "input[name='example[chain_dependent_id]'][value='dependent-south']", visible: false
  end

  test "does not auto-select a single statically rendered local option" do
    visit root_path

    assert_selector "#example_auto_local_id_summary", text: "Choose auto local item"
    assert_empty find("input[name='example[auto_local_id]']", visible: false).value
  end

  test "auto-selects the only remote option after opening" do
    visit root_path

    find("#example_auto_remote_id_trigger").click

    assert_selector "input[name='example[auto_remote_id]'][value='remote-only']", visible: false
    assert_selector "#example_auto_remote_id_summary", text: "Remote Only"
  end

  test "keeps the placeholder when auto select single is disabled" do
    visit root_path

    find("#example_auto_remote_off_id_trigger").click

    assert_selector "#example_auto_remote_off_id_options button", text: "Remote Only"
    assert_selector "#example_auto_remote_off_id_summary", text: "Search auto remote off item"
    assert_empty find("input[name='example[auto_remote_off_id]']", visible: false).value
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

  test "renders a count summary instead of tokens when summary_mode is count" do
    visit root_path

    assert_selector "#example_count_ids_summary", text: "3 selected"
    assert_no_selector "#example_count_ids_summary", text: "& +"

    find("#example_count_ids_trigger").click
    find("#example_count_ids_options button", text: "Multi Three").click
    find("#example_count_ids_trigger").send_keys(:escape)

    assert_selector "#example_count_ids_summary", text: "2 selected"
  end

  test "shows a built-in tooltip listing the selected options on hover" do
    visit root_path

    assert_selector "#example_tooltip_ids_tooltip.hidden", visible: false

    find("#example_tooltip_ids_trigger").hover

    assert_selector "#example_tooltip_ids_tooltip:not(.hidden)"
    within "#example_tooltip_ids_tooltip" do
      assert_text "Multi One"
      assert_text "Multi Two"
    end
  end

  test "renders a custom tooltip partial on hover" do
    visit root_path

    find("#example_tooltip_partial_ids_trigger").hover

    within "#example_tooltip_partial_ids_tooltip" do
      assert_selector "table.advanced-select-tooltip-table"
      assert_text "ALT-001 – Antikor A"
      assert_text "Muadil"
    end
  end

  test "rebuilds the custom tooltip partial as the selection changes" do
    visit root_path

    find("#example_tooltip_partial_ids_trigger").click
    find("#example_tooltip_partial_ids_options button", text: "ALT-003 – Antikor C").click
    find("#example_tooltip_partial_ids_trigger").click

    # Hover a different trigger first so re-hovering fires a fresh mouseenter.
    find("#example_item_id_trigger").hover
    find("#example_tooltip_partial_ids_trigger").hover

    within "#example_tooltip_partial_ids_tooltip" do
      assert_text "ALT-001 – Antikor A"
      assert_text "ALT-003 – Antikor C"
      assert_text "Eşdeğer"
    end

    find("#example_tooltip_partial_ids_trigger").click
    find("#example_tooltip_partial_ids_options button", text: "ALT-001 – Antikor A").click
    find("#example_tooltip_partial_ids_trigger").click

    find("#example_item_id_trigger").hover
    find("#example_tooltip_partial_ids_trigger").hover

    within "#example_tooltip_partial_ids_tooltip" do
      assert_no_text "ALT-001 – Antikor A"
      assert_text "ALT-003 – Antikor C"
    end
  end

  private

  def assert_selected_option_check(select_id, text)
    option = find("##{select_id}_options button[aria-selected='true']", text: text)

    assert_equal "\u2713", option.find("[data-advanced-select-option-check]").text
  end

  def assert_first_option_value(select_id, value)
    assert_selector "##{select_id}_options button:first-child[data-advanced-select-value-param='#{value}']"
  end
end
