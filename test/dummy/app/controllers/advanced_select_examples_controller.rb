class AdvancedSelectExamplesController < ApplicationController
  helper_method :styled_advanced_select_classes
  helper_method :styled_advanced_select_append_classes

  def show
  end

  def options
    @target_id = params.fetch(:target)
    @query = params[:query].to_s
    return head :internal_server_error if @target_id == "example_error_id_options"

    @options = options_for_target.select { |option| option.fetch(:label).downcase.include?(@query.downcase) }

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

  def options_for_target
    return dependent_options if @target_id == "example_dependent_id_options"

    remote_options
  end

  def dependent_options
    [
      { id: "dependent-#{params[:region]}", label: "Dependent #{params[:region].to_s.titleize}" }
    ]
  end
end
