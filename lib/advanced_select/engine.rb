module AdvancedSelect
  class Engine < ::Rails::Engine
    initializer "advanced_select.helper" do
      ActiveSupport.on_load(:action_view) do
        include AdvancedSelect::Helper
      end
    end

    initializer "advanced_select.assets" do |app|
      if app.config.respond_to?(:assets)
        javascript_path = root.join("app/javascript")
        controller_asset = "advanced_select/advanced_select_controller.js"

        unless app.config.assets.paths.map(&:to_s).include?(javascript_path.to_s)
          app.config.assets.paths << javascript_path
        end

        unless app.config.assets.precompile.include?(controller_asset)
          app.config.assets.precompile << controller_asset
        end
      end
    end

    rake_tasks do
      load root.join("lib/tasks/advanced_select/tasks.rake")
    end
  end
end
