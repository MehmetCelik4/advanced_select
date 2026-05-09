module AdvancedSelect
  module Helper
    def advanced_select_tag(name, id:, selected:, options:, placeholder:, options_url: nil, multiple: false, searchable: true, add_mode: false, dependent_fields: {}, include_hidden: true, option_content_partial: nil, classes: {}, append_classes: {})
      selected_options = advanced_select_selected_options(selected)
      class_map = advanced_select_class_map(classes, append_classes)

      render partial: "advanced_select/select", locals: {
        name: name,
        id: id,
        options_url: options_url,
        selected_options: selected_options,
        options: options,
        placeholder: placeholder,
        multiple: multiple,
        searchable: searchable && options_url.present?,
        add_mode: add_mode,
        dependent_fields: dependent_fields,
        include_hidden: include_hidden,
        target_id: "#{id}_options",
        option_content_partial: option_content_partial,
        class_map: class_map
      }
    end

    def advanced_select_options_tag(target_id:, selected:, options:, multiple: false, add_mode: false, query: nil, option_content_partial: nil, classes: {}, append_classes: {})
      render partial: "advanced_select/options", locals: {
        target_id: target_id,
        selected_options: advanced_select_selected_options(selected),
        options: options,
        multiple: multiple,
        add_mode: add_mode,
        query: query,
        option_content_partial: option_content_partial,
        class_map: advanced_select_class_map(classes, append_classes)
      }
    end

    def advanced_select_class(class_map, *keys)
      class_map.class_name(*keys)
    end

    def advanced_select_state_class(class_map, key)
      class_map.state_class(key)
    end

    def advanced_select_selected_options(selected)
      advanced_select_array(selected).map do |option|
        {
          id: option.fetch(:id).to_s,
          value: advanced_select_option_value(option),
          label: advanced_select_option_label(option),
          display_label: advanced_select_option_display_label(option)
        }
      end
    end

    def advanced_select_selected_value(selected_options)
      selected_options.map do |option|
        option.merge(displayLabel: option.fetch(:display_label))
      end.to_json
    end

    def advanced_select_option_tag(option, selected_options, option_content_partial, class_map, selected_option_ids: nil)
      selected = advanced_select_option_selected?(option, selected_options, selected_option_ids)

      tag.button(
        type: "button",
        class: advanced_select_class(class_map, :option, (:option_selected if selected)),
        role: "option",
        aria: { selected: selected },
        data: {
          advanced_select_option: "",
          action: "mouseenter->advanced-select#activateOption mousedown->advanced-select#choose",
          advanced_select_value_param: option.fetch(:id),
          advanced_select_submit_value_param: advanced_select_option_value(option),
          advanced_select_label_param: advanced_select_option_label(option),
          advanced_select_display_label_param: advanced_select_option_display_label(option)
        }
      ) do
        safe_join([
          tag.span(
            (selected ? "\u2713" : ""),
            class: advanced_select_class(class_map, :option_check),
            data: { advanced_select_option_check: "" }
          ),
          advanced_select_option_content_tag(option, option_content_partial, class_map)
        ])
      end
    end

    def advanced_select_option_content_tag(option, option_content_partial, class_map)
      if option_content_partial.present?
        render partial: option_content_partial, locals: { option: option }
      else
        advanced_select_default_option_content_tag(option, class_map)
      end
    end

    def advanced_select_default_option_content_tag(option, class_map)
      description = advanced_select_option_description(option)
      content = [tag.span(advanced_select_option_label(option))]

      if description.present?
        content << tag.span(
          description,
          class: advanced_select_class(class_map, :option_description)
        )
      end

      tag.span(safe_join(content), class: advanced_select_class(class_map, :option_content))
    end

    def advanced_select_options_for_render(options, selected_options, searchable)
      searchable ? selected_options.presence || options : options
    end

    def advanced_select_add_option?(options, selected_options, add_mode, query)
      return false unless add_mode && query.present?

      query_label = advanced_select_normalized_label(query)
      advanced_select_matched_labels(options, selected_options).none? do |label|
        advanced_select_normalized_label(label) == query_label
      end
    end

    def advanced_select_option_groups(options)
      options.map do |option|
        if option.key?(:options)
          { label: option.fetch(:label), options: option.fetch(:options) }
        else
          { label: nil, options: [option] }
        end
      end
    end

    def advanced_select_selected_option_ids(selected_options)
      selected_options.each_with_object({}) do |selected_option, selected_option_ids|
        selected_option_ids[selected_option.fetch(:id).to_s] = true
      end
    end

    def advanced_select_option_selected?(option, selected_options, selected_option_ids = nil)
      return selected_option_ids.key?(option.fetch(:id).to_s) if selected_option_ids

      selected_options.any? { |selected_option| selected_option.fetch(:id).to_s == option.fetch(:id).to_s }
    end

    def advanced_select_options_empty?(options)
      advanced_select_flat_options(options).empty?
    end

    def advanced_select_option_label(option)
      option.fetch(:label, option.fetch(:display_label, option.fetch(:value, option.fetch(:id)))).to_s
    end

    def advanced_select_option_value(option)
      option.fetch(:value, option.fetch(:id)).to_s
    end

    def advanced_select_option_display_label(option)
      option.fetch(:display_label, advanced_select_display_label(advanced_select_option_label(option))).to_s
    end

    def advanced_select_option_description(option)
      option[:description].to_s
    end

    def advanced_select_display_label(label)
      label.to_s.split(" > ").last
    end

    def advanced_select_array(value)
      case value
      when nil
        []
      when Array
        value.compact
      else
        [value]
      end
    end

    def advanced_select_matched_labels(options, selected_options)
      option_labels = advanced_select_flat_options(options).flat_map do |option|
        label = advanced_select_option_label(option)
        [label, advanced_select_option_display_label(option)]
      end

      selected_labels = selected_options.flat_map do |option|
        [advanced_select_option_label(option), advanced_select_option_display_label(option)]
      end

      option_labels + selected_labels
    end

    def advanced_select_normalized_label(label)
      I18n.transliterate(label.to_s.squish).downcase
    end

    def advanced_select_flat_options(options)
      options.flat_map { |option| option.key?(:options) ? option.fetch(:options) : option }
    end

    def advanced_select_class_map(classes, append_classes = {})
      if classes.is_a?(AdvancedSelect::ClassMap)
        classes
      else
        AdvancedSelect::ClassMap.new(classes, append_classes)
      end
    end
  end
end
