require 'json'

class ErrorReporting
  class ServerError < StandardError; end
  class BadRequestError < StandardError; end

  def self.catch_exceptions
    yield
  rescue => error
    unless error.class <= BadRequestError
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
    end

    error
  end

  def self.catch_and_respond(cgi, &block)
    if error = catch_exceptions(&block)
      status = if error.class <= BadRequestError
                 "BAD_REQUEST"
               else
                 "SERVER_ERROR"
               end

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => status do
        render "error.html", error: error
      end
    end
  end
end