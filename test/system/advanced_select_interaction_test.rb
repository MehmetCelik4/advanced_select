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
      assert_text "CD19"
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
      assert_text "HER2"
    end

    find("#example_tooltip_partial_ids_trigger").click
    find("#example_tooltip_partial_ids_options button", text: "ALT-001 – Antikor A").click
    find("#example_tooltip_partial_ids_trigger").click

    find("#example_item_id_trigger").hover
    find("#example_tooltip_partial_ids_trigger").hover

    within "#example_tooltip_partial_ids_tooltip" do
      assert_no_text "ALT-001 – Antikor A"
      assert_text "ALT-003 – Antikor C"
      assert_text "HER2"
    end
  end

  test "broadcasts advanced-select:change with the selected value" do
    visit root_path
    record_advanced_select_events("example[item_id]")

    find("#example_item_id_trigger").click
    find("#example_item_id_options button", text: "Local One").click

    assert_selector "#example_item_id_summary", text: "Local One"

    event = advanced_select_events.last

    assert_equal 1, advanced_select_events.size
    assert_equal "example[item_id]", event["name"]
    assert_equal "local-1", event["value"]
    assert_equal ["Local One"], event["options"].map { |option| option["label"] }
  end

  test "broadcasts the submit value rather than the option id" do
    visit root_path
    record_advanced_select_events("example[submit_id]")

    find("#example_submit_id_trigger").click
    find("#example_submit_id_options button", text: "Submit Item").click

    assert_selector "#example_submit_id_summary", text: "Submit Item"
    assert_equal "submit-7", advanced_select_events.last["value"]
  end

  test "broadcasts an array of values for multiple selects" do
    visit root_path
    record_advanced_select_events("example[multiple_ids][]")

    find("#example_multiple_ids_trigger").click
    find("#example_multiple_ids_options button", text: "Multi One").click
    find("#example_multiple_ids_options button", text: "Multi Two").click

    assert_selector "#example_multiple_ids_summary", text: "Multi Two"
    assert_equal [["multi-1"], %w[multi-2 multi-1]], advanced_select_events.map { |event| event["value"] }
  end

  test "broadcasts when the last value is cleared without a blank hidden field" do
    visit root_path

    find("#example_multiple_ids_without_blank_trigger").click
    find("#example_multiple_ids_without_blank_options button", text: "Multi One").click

    assert_selector "input[name='example[multiple_ids_without_blank][]'][value='multi-1']", visible: false

    record_advanced_select_events("example[multiple_ids_without_blank][]")
    find("#example_multiple_ids_without_blank_clear").click

    assert_no_selector "input[name='example[multiple_ids_without_blank][]']", visible: false
    assert_equal [[]], advanced_select_events.map { |event| event["value"] }
  end

  test "builds an option element with the same shape as a server-rendered one" do
    visit root_path

    server = option_shape("document.querySelector(\"#example_item_id_options [data-advanced-select-value-param='local-1']\")")
    client = option_shape(build_option_script("example_item_id", "{ id: 'local-1', label: 'Local One' }"))

    assert_equal server, client
  end

  test "builds option elements with the host class map" do
    visit root_path

    client = option_shape(build_option_script("example_styled_id", "{ id: 'styled-3', label: 'Styled Three' }"))
    server = option_shape("document.querySelector(\"#example_styled_id_options [data-advanced-select-value-param='styled-2']\")")

    assert_equal "test-option-class", client.fetch("className")
    assert_equal server.fetch("className"), client.fetch("className")
    assert_equal server.fetch("checkClassName"), client.fetch("checkClassName")
    assert_equal server.fetch("contentClassName"), client.fetch("contentClassName")
  end

  test "renders a description on a client-built option like the server does" do
    visit root_path

    server = option_shape("document.querySelector(\"#example_described_id_options [data-advanced-select-value-param='described-1']\")")
    client = option_shape(
      build_option_script("example_described_id", "{ id: 'described-1', label: 'Described One', description: 'First description' }")
    )

    assert_equal "Described OneFirst description", server.fetch("text")
    assert_equal server, client
  end

  test "selects a client-built option that was added to the list" do
    visit root_path
    append_built_option("example_item_id", "{ id: 'local-9', label: 'Local Nine' }")

    find("#example_item_id_trigger").click
    find("#example_item_id_options button", text: "Local Nine").click

    assert_selector "#example_item_id_summary", text: "Local Nine"
    assert_selector "input[name='example[item_id]'][value='local-9']", visible: false
    assert_equal "local-9", select_call("example_item_id", "getValue()")
  end

  test "reads the submit value through getValue" do
    visit root_path

    assert_equal "", select_call("example_submit_id", "getValue()")

    find("#example_submit_id_trigger").click
    find("#example_submit_id_options button", text: "Submit Item").click

    assert_selector "#example_submit_id_summary", text: "Submit Item"
    assert_equal "submit-7", select_call("example_submit_id", "getValue()")
  end

  test "reads an array through getValue on a multiple select" do
    visit root_path

    assert_equal [], select_call("example_multiple_ids", "getValue()")

    find("#example_multiple_ids_trigger").click
    find("#example_multiple_ids_options button", text: "Multi One").click
    find("#example_multiple_ids_options button", text: "Multi Two").click

    assert_equal %w[multi-2 multi-1], select_call("example_multiple_ids", "getValue()")
  end

  test "selects a known option through setValue" do
    visit root_path
    select_call("example_item_id", "setValue('local-2')")

    assert_selector "#example_item_id_summary", text: "Local Two"
    assert_selector "input[name='example[item_id]'][value='local-2']", visible: false

    find("#example_item_id_trigger").click

    assert_selected_option_check "example_item_id", "Local Two"
  end

  test "resolves setValue against the option id as well as its submit value" do
    visit root_path
    select_call("example_submit_id", "setValue('identity-7')")

    assert_selector "#example_submit_id_summary", text: "Submit Item"
    assert_selector "input[name='example[submit_id]'][value='submit-7']", visible: false
  end

  test "keeps an unknown setValue as a raw value" do
    visit root_path
    select_call("example_item_id", "setValue('not-in-the-list')")

    assert_selector "input[name='example[item_id]'][value='not-in-the-list']", visible: false
    assert_selector "#example_item_id_summary", text: "not-in-the-list"
  end

  test "assigns every value of an array through setValue on a multiple select" do
    visit root_path
    select_call("example_multiple_ids", "setValue(['multi-1', 'multi-2'])")

    assert_selector "input[name='example[multiple_ids][]'][value='multi-1']", visible: false
    assert_selector "input[name='example[multiple_ids][]'][value='multi-2']", visible: false
    assert_equal %w[multi-1 multi-2], select_call("example_multiple_ids", "getValue()")
  end

  test "keeps only the first value of an array on a single select" do
    visit root_path
    select_call("example_item_id", "setValue(['local-2', 'local-1'])")

    assert_equal "local-2", select_call("example_item_id", "getValue()")
    assert_no_selector "input[name='example[item_id]'][value='local-1']", visible: false
  end

  test "clears the selection when setValue receives a blank value" do
    visit root_path
    select_call("example_item_id", "setValue('local-2')")

    assert_selector "input[name='example[item_id]'][value='local-2']", visible: false

    select_call("example_item_id", "setValue('')")

    assert_no_selector "input[name='example[item_id]'][value='local-2']", visible: false
    assert_equal "", select_call("example_item_id", "getValue()")
  end

  test "broadcasts a change from setValue unless it is silent" do
    visit root_path
    record_advanced_select_events("example[item_id]")

    select_call("example_item_id", "setValue('local-1')")

    assert_selector "#example_item_id_summary", text: "Local One"
    assert_equal ["local-1"], advanced_select_events.map { |event| event["value"] }

    select_call("example_item_id", "setValue('local-2', { silent: true })")

    assert_selector "#example_item_id_summary", text: "Local Two"
    assert_equal ["local-1"], advanced_select_events.map { |event| event["value"] }
  end

  test "broadcasts again after a silent setValue" do
    visit root_path
    select_call("example_item_id", "setValue('local-1', { silent: true })")

    assert_selector "#example_item_id_summary", text: "Local One"

    record_advanced_select_events("example[item_id]")
    select_call("example_item_id", "setValue('local-2')")

    assert_selector "#example_item_id_summary", text: "Local Two"
    assert_equal ["local-2"], advanced_select_events.map { |event| event["value"] }
  end

  test "re-renders the current selection through refresh" do
    visit root_path
    select_call("example_item_id", "setValue('local-1', { silent: true })")

    assert_selector "#example_item_id_summary", text: "Local One"

    page.execute_script("document.getElementById('example_item_id_summary').replaceChildren()")

    assert_selector "#example_item_id_summary", text: ""

    select_call("example_item_id", "refresh()")

    assert_selector "#example_item_id_summary", text: "Local One"
    assert_equal "local-1", select_call("example_item_id", "getValue()")
  end

  test "renders its selection but cannot be opened while disabled" do
    visit root_path

    assert_selector ".ui-advanced-select-disabled #example_disabled_id_trigger[disabled]"
    assert_selector "#example_disabled_id_summary", text: "Disabled One"
    assert_equal "none", dropdown_display("example_disabled_id")

    page.execute_script("document.getElementById('example_disabled_id_trigger').click()")

    assert_equal "none", dropdown_display("example_disabled_id")
  end

  test "leaves a disabled value out of the form" do
    visit root_path

    assert_selector "input[name='example[disabled_id]'][value='disabled-1'][disabled]", visible: false
  end

  test "hides the clear control while disabled" do
    visit root_path

    assert_no_selector "#example_disabled_id_clear", visible: true
  end

  test "enabling at runtime restores interaction and form submission" do
    visit root_path
    set_disabled("example_disabled_id", false)

    assert_no_selector ".ui-advanced-select-disabled #example_disabled_id_trigger"
    assert_no_selector "input[name='example[disabled_id]'][disabled]", visible: false

    find("#example_disabled_id_trigger").click
    find("#example_disabled_id_options button", text: "Disabled Two").click

    assert_selector "#example_disabled_id_summary", text: "Disabled Two"
    assert_selector "input[name='example[disabled_id]'][value='disabled-2']", visible: false
    assert_no_selector "input[name='example[disabled_id]'][disabled]", visible: false
  end

  test "disabling at runtime closes the dropdown and drops the value from the form" do
    visit root_path

    find("#example_item_id_trigger").click

    assert_selector "#example_item_id_options button", text: "Local One"

    set_disabled("example_item_id", true)

    assert_equal "none", dropdown_display("example_item_id")
    assert_selector ".ui-advanced-select-disabled #example_item_id_trigger[disabled]"
    assert_selector "input[name='example[item_id]'][disabled]", visible: false
  end

  test "disabling at runtime hides the clear control and enabling brings it back" do
    visit root_path

    find("#example_item_id_trigger").click
    find("#example_item_id_options button", text: "Local One").click

    assert_selector "#example_item_id_clear", visible: true

    set_disabled("example_item_id", true)

    assert_no_selector "#example_item_id_clear", visible: true

    set_disabled("example_item_id", false)

    assert_selector "#example_item_id_clear", visible: true
  end

  private

  def record_advanced_select_events(name)
    page.execute_script(<<~JS)
      window.__advancedSelectEvents = []
      document.addEventListener("advanced-select:change", (event) => {
        if (event.detail.name === "#{name}") {
          window.__advancedSelectEvents.push(event.detail)
        }
      })
    JS
  end

  def advanced_select_events
    page.evaluate_script("window.__advancedSelectEvents")
  end

  def append_built_option(select_id, option_json)
    page.execute_script(<<~JS)
      ((select) => select.currentOptionsTarget.appendChild(select.optionElement(#{option_json})))(
        window.Stimulus.getControllerForElementAndIdentifier(
          document.getElementById("#{select_id}_trigger").closest("[data-controller~='advanced-select']"),
          "advanced-select"
        )
      )
    JS
  end

  def build_option_script(select_id, option_json)
    <<~JS.strip
      window.Stimulus.getControllerForElementAndIdentifier(
        document.getElementById("#{select_id}_trigger").closest("[data-controller~='advanced-select']"),
        "advanced-select"
      ).optionElement(#{option_json})
    JS
  end

  def option_shape(element_script)
    page.evaluate_script(<<~JS)
      ((element) => ({
        tag: element.tagName,
        className: element.className,
        role: element.getAttribute("role"),
        ariaSelected: element.getAttribute("aria-selected"),
        action: element.dataset.action,
        value: element.dataset.advancedSelectValueParam,
        submitValue: element.dataset.advancedSelectSubmitValueParam,
        label: element.dataset.advancedSelectLabelParam,
        displayLabel: element.dataset.advancedSelectDisplayLabelParam,
        checkClassName: element.querySelector("[data-advanced-select-option-check]").className,
        contentClassName: element.children[1].className,
        childTags: Array.from(element.children[1].children).map((child) => child.tagName + ":" + child.className),
        text: element.textContent.replace(/\\s+/g, " ").trim()
      }))(#{element_script})
    JS
  end

  def select_call(select_id, expression)
    page.evaluate_script(<<~JS)
      (() => {
        const root = document.getElementById("#{select_id}_trigger").closest("[data-controller~='advanced-select']")
        return window.Stimulus.getControllerForElementAndIdentifier(root, "advanced-select").#{expression}
      })()
    JS
  end

  def dropdown_display(select_id)
    page.evaluate_script("getComputedStyle(document.getElementById('#{select_id}_dropdown')).display")
  end

  def set_disabled(select_id, disabled)
    page.execute_script(<<~JS)
      document.getElementById("#{select_id}_trigger")
              .closest("[data-controller~='advanced-select']")
              .dataset.advancedSelectDisabledValue = "#{disabled}"
    JS
  end

  def assert_selected_option_check(select_id, text)
    option = find("##{select_id}_options button[aria-selected='true']", text: text)

    assert_equal "\u2713", option.find("[data-advanced-select-option-check]").text
  end

  def assert_first_option_value(select_id, value)
    assert_selector "##{select_id}_options button:first-child[data-advanced-select-value-param='#{value}']"
  end
end
