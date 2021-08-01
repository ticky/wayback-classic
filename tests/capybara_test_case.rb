require 'capybara/minitest'
require 'stringio'
require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  # c.debug_logger = $stderr
  c.default_cassette_options = {
    record: :once,
    match_requests_on: %i[host method path query],
    allow_unused_http_interactions: false
  }
end

class RackWrapper
  LOADED_MODULES = []

  def self.call(env)
    request = Rack::Request.new(env)

    case request.path
    when '/', '/index.html'
      [200, {}, File.read('../index.html')]
    when %r{\A/cgi-bin/(?<name>[A-Za-z0-9]+)\.cgi\z}
      script_name = $~[:name]

      unless LOADED_MODULES.include? script_name
        load "../cgi-bin/#{script_name}.cgi"
        LOADED_MODULES.push script_name
      end

      class_name = script_name.split(/[-_]/).map do |segment|
        segment = segment.downcase
        segment[0] = segment[0].upcase
        segment
      end.join ''

      klass = Object.const_get("WaybackClassic::#{class_name}")

      capture_cgi(env) { klass.run }
    end
  end

  # Passed a Rack env variable, and a block, executes the block with the
  # CGI response converted to be a Rack-compliant response
  def self.capture_cgi(env)
    # Hold onto a copy of the pre-execution ENV, as we need to replace it
    orig_env = ENV.to_h

    # Replace ENV with a copy of the one Rack generates, minus any rack-specific portions
    ENV.replace env.select { |key, value| !key.start_with?('rack.') && !value.is_a?(Array) }

    # Begin to capture stdout so we can manipulate the response data
    captured_stdout = StringIO.new
    orig_stdout = $stdout
    $stdout = captured_stdout

    # TODO: Do we need to do this with stderr as well? Not sure!
    # captured_stderr = StringIO.new
    # orig_stderr = $stderr
    # $stderr = captured_stderr

    # Let the CGI application run
    yield

    # Split the output into headers and body
    headers_str, body = captured_stdout.string.split("\r\n\r\n")

    headers = headers_str.split("\r\n").map do |line|
      line.split(': ', 2)
    end.to_h

    # Pluck out the CGI status header and convert it to an integer
    status = headers.delete('Status').split(' ', 2).first.to_i

    # Return a Rack-compliant response triplet
    [status, headers, body]
  ensure
    # Clean up after ourselves, restoring stdout and ENV
    $stdout = orig_stdout
    # $stderr = orig_stderr
    ENV.replace orig_env
  end
end

class CapybaraTestCase < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    Capybara.app = RackWrapper
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
