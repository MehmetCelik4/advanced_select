require "test_helper"
require "fileutils"
require "open3"
require "rails/generators/test_case"
require "generators/advanced_select/install/install_generator"

class AdvancedSelectInstallGeneratorTest < Rails::Generators::TestCase
  tests AdvancedSelect::Generators::InstallGenerator
  destination File.expand_path("../../../tmp/generators/install", __dir__)
  setup :prepare_destination

  test "registers importmap engine controller and imports engine assets" do
    write_destination_file "config/importmap.rb", <<~RUBY
      pin "application"
      pin "@hotwired/turbo-rails", to: "turbo.min.js"
      pin "@hotwired/stimulus", to: "stimulus.min.js"
    RUBY
    write_destination_file "app/javascript/controllers/index.js", <<~JS
      import { application } from "controllers/application"
      import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

      eagerLoadControllersFrom("controllers", application)
    JS
    write_destination_file "app/assets/stylesheets/application.css", <<~CSS
      /*
       *= require_tree .
       *= require_self
       */
    CSS

    run_generator

    assert_no_file "app/javascript/controllers/advanced_select_controller.js"
    assert_no_file "app/assets/stylesheets/advanced_select.css"

    assert_file "config/importmap.rb" do |content|
      assert_includes content, 'pin "advanced_select/advanced_select_controller", to: "advanced_select/advanced_select_controller.js"'
    end

    assert_file "app/javascript/controllers/index.js" do |content|
      assert_includes content, 'import AdvancedSelectController from "advanced_select/advanced_select_controller"'
      assert_includes content, 'application.register("advanced-select", AdvancedSelectController)'
    end

    assert_file "app/assets/stylesheets/application.css" do |content|
      assert_includes content, " *= require advanced_select/advanced_select\n *= require_self"
    end
  end

  test "registers the controller and imports css for jsbundling style apps" do
    write_destination_file "app/javascript/controllers/index.js", <<~JS
      import { application } from "./application"

      import ExistingController from "./existing_controller"
      application.register("existing", ExistingController)
    JS
    write_destination_file "app/assets/stylesheets/application.postcss.css", <<~CSS
      @import "tailwindcss";
    CSS

    run_generator [ "--setup=jsbundling" ]

    assert_file "app/javascript/controllers/advanced_select_controller.js" do |content|
      assert_includes content, "export default class extends Controller"
    end

    assert_file "app/assets/stylesheets/advanced_select.css" do |content|
      assert_includes content, ".ui-advanced-select"
    end

    assert_file "app/javascript/controllers/index.js" do |content|
      assert_includes content, 'import AdvancedSelectController from "./advanced_select_controller"'
      assert_includes content, 'application.register("advanced-select", AdvancedSelectController)'
    end

    assert_file "app/assets/stylesheets/application.postcss.css" do |content|
      assert_includes content, '@import "advanced_select.css";'
    end
  end

  test "bundles the jsbundling setup with esbuild" do
    write_jsbundling_fixture

    run_generator [ "--setup=jsbundling" ]

    assert_esbuild "app/javascript/application.js", "app/assets/builds/application.js"
    assert_esbuild "app/assets/stylesheets/application.postcss.css", "app/assets/builds/application.css"

    assert_file "app/assets/builds/application.js" do |content|
      assert_includes content, "advanced-select"
    end

    assert_file "app/assets/builds/application.css" do |content|
      assert_includes content, ".ui-advanced-select"
    end
  end

  test "keeps importmap eager loading setup and adds explicit engine registration" do
    write_destination_file "app/javascript/controllers/index.js", <<~JS
      import { application } from "controllers/application"
      import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

      eagerLoadControllersFrom("controllers", application)
    JS

    run_generator

    assert_file "app/javascript/controllers/index.js" do |content|
      assert_includes content, "eagerLoadControllersFrom"
      assert_includes content, 'application.register("advanced-select", AdvancedSelectController)'
    end
  end

  test "adds stylesheet require to importmap application css manifest" do
    write_importmap_controller_index
    write_destination_file "app/assets/stylesheets/application.css", <<~CSS
      /*
       *= require base
       *= require_self
       */

      body {
        color: #111827;
      }
    CSS

    run_generator

    assert_file "app/assets/stylesheets/application.css" do |content|
      assert_includes content, " *= require advanced_select/advanced_select\n *= require_self"
    end
  end

  test "adds stylesheet require even when importmap application css requires tree" do
    write_importmap_controller_index
    write_destination_file "app/assets/stylesheets/application.css", <<~CSS
      /*
       *= require_tree .
       *= require_self
       */
    CSS

    run_generator

    assert_file "app/assets/stylesheets/application.css" do |content|
      assert_includes content, " *= require_tree ."
      assert_includes content, " *= require advanced_select/advanced_select"
    end
  end

  test "does not duplicate importmap stylesheet require" do
    write_importmap_controller_index
    write_destination_file "app/assets/stylesheets/application.css", <<~CSS
      /*
       *= require advanced_select/advanced_select
       *= require_self
       */
    CSS

    run_generator

    assert_file "app/assets/stylesheets/application.css" do |content|
      assert_equal 1, content.scan("require advanced_select/advanced_select").size
    end
  end

  test "does not duplicate importmap controller pin" do
    write_importmap_controller_index
    write_destination_file "config/importmap.rb", <<~RUBY
      pin "application"
      pin "advanced_select/advanced_select_controller", to: "advanced_select/advanced_select_controller.js"
    RUBY

    run_generator

    assert_file "config/importmap.rb" do |content|
      assert_equal 1, content.scan('pin "advanced_select/advanced_select_controller"').size
    end
  end

  test "does not duplicate importmap controller registration" do
    write_destination_file "app/javascript/controllers/index.js", <<~JS
      import { application } from "controllers/application"
      import AdvancedSelectController from "advanced_select/advanced_select_controller"
      application.register("advanced-select", AdvancedSelectController)
    JS

    run_generator

    assert_file "app/javascript/controllers/index.js" do |content|
      assert_equal 1, content.scan("advanced-select").size
    end
  end

  private

  def write_importmap_controller_index
    write_destination_file "app/javascript/controllers/index.js", <<~JS
      import { application } from "controllers/application"
      import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

      eagerLoadControllersFrom("controllers", application)
    JS
  end

  def write_jsbundling_fixture
    write_destination_file "app/javascript/application.js", <<~JS
      import "@hotwired/turbo-rails"
      import "./controllers"
    JS
    write_destination_file "app/javascript/controllers/application.js", <<~JS
      import { Application } from "@hotwired/stimulus"

      const application = Application.start()
      window.Stimulus = application

      export { application }
    JS
    write_destination_file "app/javascript/controllers/index.js", <<~JS
      import { application } from "./application"
    JS
    write_destination_file "app/assets/stylesheets/application.postcss.css", <<~CSS
      body {
        color: #111827;
      }
    CSS
    write_destination_file "node_modules/@hotwired/stimulus/index.js", <<~JS
      export class Controller {}

      export class Application {
        static start() {
          return new Application()
        }

        register(identifier) {
          window.__stimulusControllers ||= []
          window.__stimulusControllers.push(identifier)
        }
      }
    JS
    write_destination_file "node_modules/@hotwired/turbo-rails/index.js", <<~JS
      export const Turbo = {
        renderStreamMessage() {}
      }
    JS
  end

  def assert_esbuild(entrypoint, outfile)
    FileUtils.mkdir_p(File.dirname(File.join(destination_root, outfile)))
    stdout, stderr, status = Open3.capture3(
      "esbuild",
      entrypoint,
      "--bundle",
      "--format=esm",
      "--outfile=#{outfile}",
      chdir: destination_root
    )

    assert status.success?, "esbuild failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end

  def write_destination_file(path, content)
    destination = File.join(destination_root, path)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, content)
  end
end
