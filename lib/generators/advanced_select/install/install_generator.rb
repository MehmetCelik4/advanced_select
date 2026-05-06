module AdvancedSelect
  module Generators
    class InstallGenerator < Rails::Generators::Base
      VALID_SETUPS = %w[importmap jsbundling].freeze

      source_root File.expand_path("templates", __dir__)
      class_option :setup,
                   type: :string,
                   default: "importmap",
                   desc: "Host app setup: importmap or jsbundling"

      def validate_options
        return if VALID_SETUPS.include?(setup)

        raise Thor::Error, "Invalid --setup=#{setup.inspect}. Expected one of: #{VALID_SETUPS.join(', ')}."
      end

      def copy_stimulus_controller
        copy_file "advanced_select_controller.js", "app/javascript/controllers/advanced_select_controller.js"
      end

      def copy_stylesheet
        copy_file "advanced_select.css", "app/assets/stylesheets/advanced_select.css"
      end

      def register_stimulus_controller
        case setup
        when "importmap"
          say "Importmap setup selected; stimulus-rails eager loading should load advanced_select_controller.js."
        when "jsbundling"
          register_manifest_controller
        end
      end

      def import_stylesheet
        case setup
        when "importmap"
          import_application_stylesheet
        when "jsbundling"
          append_postcss_import
        end
      end

      def show_next_steps
        say "AdvancedSelect installed.", :green
        say "Setup: #{setup}"
        say "Host apps still own routes, controllers, queries, and Turbo Stream option endpoints."
      end

      private

      def register_manifest_controller
        unless File.exist?(target_path("app/javascript/controllers/index.js"))
          raise Thor::Error, "Could not find app/javascript/controllers/index.js for --setup=jsbundling."
        end
        return if file_contains?("app/javascript/controllers/index.js", "advanced-select")

        append_to_file "app/javascript/controllers/index.js", <<~JS

          import AdvancedSelectController from "./advanced_select_controller"
          application.register("advanced-select", AdvancedSelectController)
        JS
      end

      def append_postcss_import
        path = "app/assets/stylesheets/application.postcss.css"
        unless File.exist?(target_path(path))
          raise Thor::Error, "Could not find #{path} for --setup=jsbundling."
        end
        return if file_contains?(path, "advanced_select.css")

        insert_css_import(path)
      end

      def import_application_stylesheet
        path = "app/assets/stylesheets/application.css"
        unless File.exist?(target_path(path))
          say "Could not find #{path}; load app/assets/stylesheets/advanced_select.css through your host app stylesheet entrypoint."
          return
        end

        if file_contains?(path, "advanced_select")
          say "#{path} already references advanced_select.css."
        elsif application_css_requires_tree?(path)
          say "#{path} uses require_tree .; copied stylesheet should be included automatically."
        elsif sprockets_manifest?(path)
          insert_sprockets_require(path)
        else
          say "Could not safely patch #{path}; load app/assets/stylesheets/advanced_select.css through your host app stylesheet entrypoint."
        end
      end

      def file_contains?(path, content)
        File.exist?(target_path(path)) && File.read(target_path(path)).include?(content)
      end

      def application_css_requires_tree?(path)
        File.readlines(target_path(path)).any? { |line| line.match?(%r{^\s*\*=\s*require_tree\s+\.\s*$}) }
      end

      def sprockets_manifest?(path)
        content = File.read(target_path(path))
        content.include?("/*") && content.include?("*/") && content.include?("*=")
      end

      def insert_sprockets_require(path)
        lines = File.readlines(target_path(path))
        insert_at = lines.index { |line| line.match?(%r{^\s*\*=\s*require_self\s*$}) }
        insert_at ||= lines.index { |line| line.strip == "*/" }

        lines.insert(insert_at, " *= require advanced_select\n")
        File.write(target_path(path), lines.join)
      end

      def insert_css_import(path)
        lines = File.readlines(target_path(path))
        import_index = lines.rindex { |line| line.strip.start_with?("@import") }
        lines.insert((import_index || -1) + 1, "@import \"advanced_select.css\";\n")

        File.write(target_path(path), lines.join)
      end

      def setup
        options[:setup].to_s
      end

      def target_path(path)
        File.join(destination_root, path)
      end
    end
  end
end
