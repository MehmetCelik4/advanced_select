require_relative "lib/advanced_select/version"

Gem::Specification.new do |spec|
  spec.name        = "advanced_select"
  spec.version     = AdvancedSelect::VERSION
  spec.authors     = [ "Mehmet Celik" ]
  spec.email       = [ "mehmetcelik4@gmail.com" ]
  spec.summary     = "Reusable Rails advanced select UI engine."
  spec.description = "AdvancedSelect provides helper-rendered Rails views, Stimulus behavior, and plain CSS for an advanced select input."
  spec.homepage    = "https://github.com/MehmetCelik4/advanced_select"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.metadata    = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases"
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "actionview", ">= 7.1"
  spec.add_dependency "railties", ">= 7.1"
  spec.add_dependency "stimulus-rails", ">= 1.3"
  spec.add_dependency "turbo-rails", ">= 2.0"

  spec.add_development_dependency "minitest", "~> 5.0"
end
