class AdvancedSelectExamplesController < ApplicationController
  def show
  end

  def options
    @target_id = params.fetch(:target)
    @query = params[:query].to_s
    @options = remote_options.select { |option| option.fetch(:label).downcase.include?(@query.downcase) }

    render formats: :turbo_stream
  end

  private

  def remote_options
    [
      { id: "remote-1", label: "Remote Alpha" },
      { id: "remote-2", label: "Remote Beta" }
    ]
  end
end
