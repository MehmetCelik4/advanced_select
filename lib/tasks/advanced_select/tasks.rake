namespace :advanced_select do
  desc "Install AdvancedSelect assets into the host Rails app"
  task :install do
    command = [ "bin/rails", "generate", "advanced_select:install" ]
    command << "--setup=#{ENV.fetch('SETUP')}" if ENV["SETUP"]

    abort "AdvancedSelect install generator failed." unless system(*command)
  end
end
