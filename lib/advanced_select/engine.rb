module AdvancedSelect
  class Engine < ::Rails::Engine
    initializer "advanced_select.helper" do
      ActiveSupport.on_load(:action_view) do
        include AdvancedSelect::Helper
      end
    end

    rake_tasks do
      load root.join("lib/tasks/advanced_select/tasks.rake")
    end
  end
end
