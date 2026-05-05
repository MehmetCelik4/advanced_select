require "application_system_test_case"
require "fileutils"
require "net/http"
require "open3"
require "socket"
require "timeout"

class JsBundlingAdvancedSelectInteractionTest < ApplicationSystemTestCase
  setup do
    build_jsbundling_assets
    @server_port = find_available_port
    start_jsbundling_dummy_server
  end

  teardown do
    stop_jsbundling_dummy_server
  end

  test "selects local options and remote Turbo Stream options from the jsbundling dummy app" do
    visit "http://127.0.0.1:#{@server_port}/"

    assert_equal "flex", page.evaluate_script("getComputedStyle(document.querySelector('#example_item_id_trigger')).display")

    find("#example_item_id_trigger").click
    find("#example_item_id_options button", text: "Local One").click

    assert_selector "input[name='example[item_id]'][value='local-1']", visible: false
    assert_selector "#example_item_id_summary", text: "Local One"

    find("#example_remote_id_trigger").click
    fill_in "example_remote_id_search", with: "Beta"

    assert_selector "#example_remote_id_options button", text: "Remote Beta"

    find("#example_remote_id_options button", text: "Remote Beta").click

    assert_selector "input[name='example[remote_id]'][value='remote-2']", visible: false
    assert_selector "#example_remote_id_summary", text: "Remote Beta"
  end

  private

  def build_jsbundling_assets
    write_hotwire_shim(
      "@hotwired/stimulus",
      Gem.loaded_specs.fetch("stimulus-rails").full_gem_path,
      "app/assets/javascripts/stimulus.js"
    )
    write_hotwire_shim(
      "@hotwired/turbo-rails",
      Gem.loaded_specs.fetch("turbo-rails").full_gem_path,
      "app/assets/javascripts/turbo.js"
    )

    run_jsbundling_command(
      "esbuild",
      "app/javascript/application.js",
      "--bundle",
      "--format=esm",
      "--outfile=app/assets/builds/application.js"
    )
    run_jsbundling_command(
      "esbuild",
      "app/assets/stylesheets/application.postcss.css",
      "--bundle",
      "--outfile=app/assets/builds/application.css"
    )
  end

  def write_hotwire_shim(package_name, gem_path, asset_path)
    [ jsbundling_dummy_root, AdvancedSelect::Engine.root ].each do |root|
      shim_path = root.join("node_modules", package_name, "index.js")
      FileUtils.mkdir_p(shim_path.dirname)
      File.write(shim_path, %(export * from "#{File.join(gem_path, asset_path)}"\n))
    end
  end

  def run_jsbundling_command(*command)
    FileUtils.mkdir_p(jsbundling_dummy_root.join("app/assets/builds"))
    stdout, stderr, status = Open3.capture3(*command, chdir: jsbundling_dummy_root.to_s)

    assert status.success?, "#{command.join(' ')} failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end

  def start_jsbundling_dummy_server
    env = { "RAILS_ENV" => "test" }
    @server_stdin, @server_output, @server_wait_thread = Open3.popen2e(
      env,
      "bundle",
      "exec",
      "ruby",
      "bin/rails",
      "server",
      "-e",
      "test",
      "-p",
      @server_port.to_s,
      "-b",
      "127.0.0.1",
      chdir: jsbundling_dummy_root.to_s
    )
    @server_log = []
    @server_reader = Thread.new do
      @server_output.each_line { |line| @server_log << line }
    end
    wait_for_jsbundling_dummy_server
  end

  def wait_for_jsbundling_dummy_server
    Timeout.timeout(20) do
      loop do
        response = Net::HTTP.get_response(URI("http://127.0.0.1:#{@server_port}/"))
        break if response.is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
        raise "jsbundling dummy server exited:\n#{@server_log.join}" unless @server_wait_thread.alive?

        sleep 0.1
      end
    end
  rescue Timeout::Error
    raise "jsbundling dummy server did not start:\n#{@server_log.join}"
  end

  def stop_jsbundling_dummy_server
    return unless @server_wait_thread

    Process.kill("TERM", @server_wait_thread.pid) if @server_wait_thread.alive?
    Timeout.timeout(5) { @server_wait_thread.value }
  rescue Timeout::Error
    Process.kill("KILL", @server_wait_thread.pid) if @server_wait_thread.alive?
  ensure
    @server_stdin&.close
    @server_output&.close
    @server_reader&.kill
  end

  def find_available_port
    TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] }
  end

  def jsbundling_dummy_root
    Rails.root.join("../dummy_jsbundling").expand_path
  end
end
