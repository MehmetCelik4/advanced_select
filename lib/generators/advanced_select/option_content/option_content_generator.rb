module AdvancedSelect
  module Generators
    class OptionContentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_option_content_partial
        template "option_content.html.erb", "app/views/advanced_select/option_contents/_#{file_name}.html.erb"
      end
    end
  end
end
