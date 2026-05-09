require "test_helper"

class AdvancedSelectHelperTest < ActionView::TestCase
  include AdvancedSelect::Helper

  setup do
    controller.prepend_view_path AdvancedSelect::Engine.root.join("app/views")
    I18n.locale = :en
  end

  test "renders a selected single select" do
    fragment = html_fragment(
      advanced_select_tag(
        "cost_allocation[customer_hierarchy_id]",
        id: "cost_allocation_customer_hierarchy_id",
        options_url: "/cost_allocations/customer_hierarchy_options",
        selected: { id: 42, label: "Turkiye > Istanbul > Moda" },
        options: [],
        placeholder: "Select"
      )
    )

    selected_value = JSON.parse(fragment.at_css(".ui-advanced-select")["data-advanced-select-selected-value"])

    assert_selector fragment, "input[type='hidden'][name='cost_allocation[customer_hierarchy_id]'][value='42']", visible: false
    assert_selector fragment, "#cost_allocation_customer_hierarchy_id_summary .ui-advanced-select-value", text: "Moda"
    assert_selector fragment, "#cost_allocation_customer_hierarchy_id_trigger[data-action='advanced-select#toggle keydown->advanced-select#keydown']"
    assert_equal(
      [
        {
          "id" => "42",
          "value" => "42",
          "label" => "Turkiye > Istanbul > Moda",
          "display_label" => "Moda",
          "displayLabel" => "Moda"
        }
      ],
      selected_value
    )
  end

  test "renders grouped options with descriptions" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[item]",
        id: "report_grouped_item",
        selected: nil,
        options: [
          {
            label: "Recent",
            options: [
              { id: "recent-1", label: "Recent item", description: "Last used" }
            ]
          },
          {
            label: "All",
            options: [
              { id: "all-1", label: "All item", description: "Every record" }
            ]
          }
        ],
        placeholder: "Select",
        searchable: false
      )
    )

    assert_selector fragment, ".ui-advanced-select-group-label", text: "Recent"
    assert_selector fragment, ".ui-advanced-select-group-label", text: "All"
    assert_selector fragment, "#report_grouped_item_options button[data-advanced-select-value-param='recent-1']", text: "Recent item"
    assert_selector fragment, "#report_grouped_item_options .ui-advanced-select-option-description", text: "Last used"
  end

  test "renders default option rows without per-option internal partials" do
    partials = rendered_partials do
      fragment = html_fragment(
        advanced_select_tag(
          "report[item]",
          id: "report_fast_item",
          selected: { id: "item-2", label: "Item two" },
          options: [
            { id: "item-1", label: "Item one" },
            { id: "item-2", label: "Item two", description: "Selected" },
            { id: "item-3", label: "Item three" }
          ],
          placeholder: "Select",
          searchable: false
        )
      )

      assert_selector fragment, "#report_fast_item_options button[data-advanced-select-value-param='item-2'][aria-selected='true']"
      assert_selector fragment, "#report_fast_item_options .ui-advanced-select-option-description", text: "Selected"
    end

    assert_includes partials, "advanced_select/_options"
    refute_includes partials, "advanced_select/_option"
    refute_includes partials, "advanced_select/_default_option_content"
  end

  test "renders public styling hooks" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[items][]",
        id: "report_style_hooks",
        selected: [{ id: "item-1", label: "Item one" }],
        options: [{ id: "item-1", label: "Item one", description: "Description" }],
        placeholder: "Select",
        multiple: true,
        add_mode: true,
        searchable: false
      )
    )

    assert_selector fragment, ".ui-advanced-select"
    assert_selector fragment, ".ui-advanced-select-trigger"
    assert_selector fragment, ".ui-advanced-select-dropdown"
    assert_selector fragment, ".ui-advanced-select-options"
    assert_selector fragment, ".ui-advanced-select-option"
    assert_selector fragment, ".ui-advanced-select-option[aria-selected='true']"
    assert_selector fragment, ".ui-advanced-select-token"
    assert_selector fragment, ".ui-advanced-select-option-description"
  end

  test "replaces public styling hooks with host class map values" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[item]",
        id: "report_classed_item",
        selected: { id: "item-1", label: "Item one", description: "Description" },
        options: [{ id: "item-1", label: "Item one", description: "Description" }],
        placeholder: "Select",
        searchable: false,
        classes: {
          root: "host-root",
          trigger: "host-trigger",
          dropdown: "host-dropdown",
          option: "host-option hover:bg-red-500",
          option_selected: "host-selected",
          option_check: "host-check",
          option_content: "host-content",
          option_description: "host-description"
        }
      )
    )

    assert_class_equals fragment.at_css("#report_classed_item_trigger"), "host-trigger"
    assert_class_equals fragment.at_css("#report_classed_item_dropdown"), "host-dropdown hidden"
    assert_class_equals fragment.at_css("[data-advanced-select-option]"), "host-option hover:bg-red-500 host-selected"
    assert_class_equals fragment.at_css("[data-advanced-select-option-check]"), "host-check"
    assert_class_equals fragment.at_css(".host-content"), "host-content"
    assert_class_equals fragment.at_css(".host-description"), "host-description"

    assert_no_selector fragment, ".ui-advanced-select"
    assert_no_selector fragment, ".ui-advanced-select-trigger"
    assert_no_selector fragment, ".ui-advanced-select-dropdown"
    assert_no_selector fragment, ".ui-advanced-select-option"
    assert_no_selector fragment, ".ui-advanced-select-option-check"
    assert_no_selector fragment, ".ui-advanced-select-option-content"
    assert_no_selector fragment, ".ui-advanced-select-option-description"
  end

  test "appends host classes while keeping default styling hooks" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[item]",
        id: "report_extra_classed_item",
        selected: nil,
        options: [{ id: "item-1", label: "Item one" }],
        placeholder: "Select",
        searchable: false,
        classes: {
          option: "host-option hover:bg-red-500"
        },
        append_classes: {
          trigger: "min-h-10 rounded-md border-gray-300",
          dropdown: "shadow-lg",
          option: "text-gray-700"
        }
      )
    )

    assert_class_equals fragment.at_css("#report_extra_classed_item_trigger"), "ui-advanced-select-trigger min-h-10 rounded-md border-gray-300"
    assert_class_equals fragment.at_css("#report_extra_classed_item_dropdown"), "ui-advanced-select-dropdown shadow-lg hidden"
    assert_class_equals fragment.at_css("[data-advanced-select-option]"), "host-option hover:bg-red-500 text-gray-700"

    assert_no_selector fragment, ".ui-advanced-select-option"
  end

  test "normalizes blank host classes" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[item]",
        id: "report_blank_classes",
        selected: nil,
        options: [{ id: "item-1", label: "Item one" }],
        placeholder: "Select",
        searchable: false,
        classes: { trigger: "  host-trigger   ", option: nil, dropdown: "" }
      )
    )

    assert_class_equals fragment.at_css("#report_blank_classes_trigger"), "host-trigger"
    assert_class_equals fragment.at_css("[data-advanced-select-option]"), "ui-advanced-select-option"
  end

  test "renders option-only class map for turbo stream replacements" do
    fragment = html_fragment(
      advanced_select_options_tag(
        target_id: "report_user_ids_options",
        selected: [{ id: 7, label: "Name" }],
        options: [{ id: 7, label: "Name", description: "Description" }],
        add_mode: true,
        query: "New user",
        classes: {
          options: "host-options",
          option: "host-option",
          option_selected: "host-selected",
          add_option: "host-add",
          empty: "host-empty"
        }
      )
    )

    assert_class_equals fragment.at_css("#report_user_ids_options"), "host-options"
    assert_class_equals fragment.at_css("[data-advanced-select-option]"), "host-option host-selected"
    assert_class_equals fragment.at_css("[data-advanced-select-add-option]"), "host-add"

    assert_no_selector fragment, ".ui-advanced-select-options"
    assert_no_selector fragment, ".ui-advanced-select-option"
    assert_no_selector fragment, ".ui-advanced-select-add-option"
  end

  test "renders option-only appended classes for turbo stream replacements" do
    fragment = html_fragment(
      advanced_select_options_tag(
        target_id: "report_user_ids_options",
        selected: [{ id: 7, label: "Name" }],
        options: [{ id: 7, label: "Name" }],
        classes: {
          option: "host-option",
          option_selected: "host-selected"
        },
        append_classes: {
          options: "max-h-72",
          option: "text-gray-700"
        }
      )
    )

    assert_class_equals fragment.at_css("#report_user_ids_options"), "ui-advanced-select-options max-h-72"
    assert_class_equals fragment.at_css("[data-advanced-select-option]"), "host-option text-gray-700 host-selected"

    assert_no_selector fragment, ".ui-advanced-select-option"
  end

  test "marks multiple listbox as multiselectable" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[items][]",
        id: "report_items",
        selected: [],
        options: [{ id: "item-1", label: "Item one" }],
        placeholder: "Select",
        multiple: true,
        searchable: false
      )
    )

    assert_selector fragment, "#report_items_options[role='listbox'][aria-multiselectable='true']"
  end

  test "renders a hidden blank field for multiple selects by default" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[items][]",
        id: "report_items",
        selected: [{ id: "item-1", label: "Item one" }],
        options: [{ id: "item-1", label: "Item one" }],
        placeholder: "Select",
        multiple: true,
        searchable: false
      )
    )

    inputs = fragment.css("input[type='hidden'][name='report[items][]']")

    assert_equal ["", "item-1"], inputs.map { |input| input["value"] }
    assert_nil inputs.first["id"]
  end

  test "does not render a hidden blank field when include_hidden is false" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[items][]",
        id: "report_items",
        selected: [{ id: "item-1", label: "Item one" }],
        options: [{ id: "item-1", label: "Item one" }],
        placeholder: "Select",
        multiple: true,
        include_hidden: false,
        searchable: false
      )
    )

    inputs = fragment.css("input[type='hidden'][name='report[items][]']")

    assert_equal ["item-1"], inputs.map { |input| input["value"] }
  end

  test "renders custom option content while keeping the engine option wrapper" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[item]",
        id: "report_custom_item",
        selected: nil,
        options: [{ id: "product-1", code: "P-001", label: "Product one" }],
        placeholder: "Select",
        searchable: false,
        option_content_partial: "advanced_select/option_contents/product"
      )
    )

    assert_selector fragment, "#report_custom_item_options button[role='option'][data-advanced-select-value-param='product-1']"
    assert_selector fragment, "#report_custom_item_options .custom-product-code", text: "P-001"
  end

  test "renders options only content for turbo stream replacement" do
    fragment = html_fragment(
      advanced_select_options_tag(
        target_id: "report_user_ids_options",
        selected: [],
        options: [{ id: 7, label: "Name" }],
        add_mode: true,
        query: "New user"
      )
    )

    assert_selector fragment, "#report_user_ids_options"
    assert_selector fragment, ".ui-advanced-select-add-option", text: I18n.t("shared.advanced_select.add_option", query: "New user")
    assert_selector fragment, ".ui-advanced-select-add-option[data-advanced-select-value-param='__new__:New user']"
  end

  test "renders multiple options only content as multiselectable" do
    fragment = html_fragment(
      advanced_select_options_tag(
        target_id: "report_items_options",
        selected: [],
        options: [{ id: "item-1", label: "Item one" }],
        multiple: true
      )
    )

    assert_selector fragment, "#report_items_options[role='listbox'][aria-multiselectable='true']"
  end

  test "does not render add option when the query matches an existing option" do
    fragment = html_fragment(
      advanced_select_options_tag(
        target_id: "report_user_ids_options",
        selected: [],
        options: [{ id: 7, label: "New user" }],
        add_mode: true,
        query: "new user"
      )
    )

    assert_no_selector fragment, ".ui-advanced-select-add-option"
    assert_no_selector fragment, ".ui-advanced-select-empty"
  end

  test "renders empty state when options are blank" do
    fragment = html_fragment(
      advanced_select_options_tag(
        target_id: "report_user_ids_options",
        selected: [],
        options: [],
        add_mode: false,
        query: nil
      )
    )

    assert_selector fragment, ".ui-advanced-select-empty", text: I18n.t("shared.advanced_select.empty")
  end

  test "keeps option id separate from submitted value" do
    fragment = html_fragment(
      advanced_select_tag(
        "report[item]",
        id: "report_item",
        selected: { id: "row-7", value: "submit-7", label: "Submit value" },
        options: [{ id: "row-7", value: "submit-7", label: "Submit value" }],
        placeholder: "Select",
        searchable: false
      )
    )

    assert_selector fragment, "input[type='hidden'][name='report[item]'][value='submit-7']", visible: false
    assert_selector fragment, "#report_item_options button[data-advanced-select-value-param='row-7'][data-advanced-select-submit-value-param='submit-7']"
  end

  private

  def html_fragment(html)
    Nokogiri::HTML.fragment(html.to_s)
  end

  def rendered_partials
    partials = []
    subscriber = ActiveSupport::Notifications.subscribe("render_partial.action_view") do |_event, _started, _finished, _id, payload|
      partials << rendered_partial_path(payload)
    end

    yield
    partials
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def rendered_partial_path(payload)
    virtual_path = payload[:virtual_path].to_s
    return virtual_path if virtual_path.present?

    identifier = payload[:identifier].to_s
    views_path = "#{AdvancedSelect::Engine.root}/app/views/"

    identifier.delete_prefix(views_path).delete_suffix(".html.erb").delete_suffix(".erb")
  end

  def assert_selector(fragment, selector, text: nil, visible: nil)
    matches = fragment.css(selector)
    matches = matches.select { |node| node.text.include?(text) } if text

    assert matches.any?, "Expected selector #{selector.inspect}#{text ? " with text #{text.inspect}" : nil}"
  end

  def assert_no_selector(fragment, selector)
    assert_empty fragment.css(selector), "Expected no selector #{selector.inspect}"
  end

  def assert_class_includes(node, *classes)
    class_names = node["class"].to_s.split

    classes.each do |class_name|
      assert_includes class_names, class_name
    end
  end

  def assert_no_class(node, class_name)
    refute_includes node["class"].to_s.split, class_name
  end

  def assert_class_equals(node, class_name)
    assert_equal class_name, node["class"].to_s
  end
end
