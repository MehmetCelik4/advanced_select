require_relative "lib/advanced_select/version"

Gem::Specification.new do |spec|
  spec.name        = "advanced_select"
  spec.version     = AdvancedSelect::VERSION
  spec.authors     = [ "Mehmet Celik", "Tankut Ozbeyendir", "Emre ULUSOY" ]
  spec.email       = [ "mehmetcelik4@gmail.com", "tankutozbeyendir@gmail.com", "ulsyemr@gmail.com" ]
  spec.summary     = "UI-only Rails engine for searchable advanced select inputs."
  spec.description = "AdvancedSelect provides helper-rendered Rails partials, Stimulus dropdown behavior, Turbo Stream-compatible option updates, plain CSS, and i18n defaults while leaving data loading, authorization, and endpoints to the host app."
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
