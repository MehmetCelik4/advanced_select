require "test_helper"
require "rake"

class AdvancedSelectRakeTasksTest < ActiveSupport::TestCase
  setup do
    Rake.application.clear
  end

  test "loads install task" do
    AdvancedSelect::Engine.load_tasks

    assert Rake::Task.task_defined?("advanced_select:install")
  end
end
