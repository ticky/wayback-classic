if ENV["BUGSNAG_API_KEY"]
  begin
    require 'bugsnag'

    Bugsnag.configure do |config|
      config.api_key = ENV["BUGSNAG_API_KEY"]
    end
  rescue LoadError
  end
end

def catch_exceptions
  yield
rescue => e
  Bugsnag.notify e if defined? Bugsnag
  e
end

def catch_exceptions_and_respond(cgi, &block)
  if e = catch_exceptions(&block)
    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "BAD_REQUEST" do
      render "error.html", error: e
    end
  end
end
