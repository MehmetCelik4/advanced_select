class AdvancedSelectExamplesController < ApplicationController
  helper_method :styled_advanced_select_classes
  helper_method :styled_advanced_select_append_classes

  def show
  end

  def options
    @target_id = params.fetch(:target)
    @query = params[:query].to_s
    @options = remote_options.select { |option| option.fetch(:label).downcase.include?(@query.downcase) }

    render formats: :turbo_stream
  end

  private

  def styled_advanced_select_classes
    {
      option: "test-option-class",
      option_active: "test-option-active-class test-option-active-extra",
      option_selected: "test-option-selected-class",
      add_option: "test-add-option-class",
      add_option_active: "test-add-option-active-class"
    }
  end

  def styled_advanced_select_append_classes
    {
      trigger: "test-trigger-class",
      dropdown: "test-dropdown-class"
    }
  end

  def remote_options
    [
      { id: "remote-1", label: "Remote Alpha" },
      { id: "remote-2", label: "Remote Beta" }
    ]
  end
end
