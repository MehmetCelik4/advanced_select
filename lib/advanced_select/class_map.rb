module AdvancedSelect
  class ClassMap
    DEFAULTS = {
      root: "ui-advanced-select",
      trigger: "ui-advanced-select-trigger",
      summary: "ui-advanced-select-summary",
      placeholder: "ui-advanced-select-placeholder",
      value: "ui-advanced-select-value",
      token: "ui-advanced-select-token",
      caret: "ui-advanced-select-caret",
      clear: "ui-advanced-select-clear",
      dropdown: "ui-advanced-select-dropdown",
      search: "ui-advanced-select-search",
      options: "ui-advanced-select-options",
      option: "ui-advanced-select-option",
      option_active: "ui-advanced-select-option-active",
      option_selected: "",
      option_check: "ui-advanced-select-option-check",
      option_content: "ui-advanced-select-option-content",
      option_description: "ui-advanced-select-option-description",
      group_label: "ui-advanced-select-group-label",
      add_option: "ui-advanced-select-add-option",
      add_option_active: "",
      empty: "ui-advanced-select-empty",
      loading: "ui-advanced-select-loading",
      error: "ui-advanced-select-error"
    }.freeze

    def initialize(classes = {}, append_classes = {})
      @classes = normalize(classes)
      @append_classes = normalize(append_classes)
    end

    def class_name(*keys)
      keys.compact.map { |key| class_for(key.to_sym) }.compact.reject(&:empty?).join(" ")
    end

    def state_class(key)
      class_name(key)
    end

    private

    def normalize(classes)
      classes.to_h.each_with_object({}) do |(key, value), normalized|
        class_name = value.to_s.squish
        normalized[key.to_sym] = class_name if class_name.present?
      end
    end

    def class_for(key)
      [@classes.fetch(key) { DEFAULTS[key] }, @append_classes[key]].compact.reject(&:empty?).join(" ")
    end
  end
end
