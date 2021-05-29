require 'json'

def catch_exceptions
  yield
rescue => error
  STDERR.puts JSON.dump(error: {
                          class: error.class.name,
                          message: error.message,
                          backtrace: error.backtrace
                        },
                        request: {
                          env: ENV.select do |key, value|
                            key.start_with?("HTTP_", "PATH_", "CONTENT_", "REMOTE_") ||
                              %w(QUERY_STRING REQUEST_METHOD).include?(key)
                          end
                        })

  error
end

def catch_exceptions_and_respond(cgi, &block)
  if error = catch_exceptions(&block)
    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "BAD_REQUEST" do
      render "error.html", error: error
    end
  end
end
