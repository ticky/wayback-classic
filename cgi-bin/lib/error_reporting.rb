require 'json'

module WaybackClassic
  class ErrorReporting
    class ReportableError < StandardError; end

    class ServerError < ReportableError; end

    class HandledError < ReportableError; end

    class ForbiddenError < HandledError; end

    class NotFoundError < HandledError; end

    class BadRequestError < HandledError; end

    def self.catch_exceptions
      yield
    rescue StandardError => error
      unless error.class <= HandledError
        warn JSON.dump(error: {
                         class: error.class.name,
                         message: error.message,
                         backtrace: error.backtrace
                       },
                       request: {
                         env: ENV.select do |key, _value|
                           key.start_with?('HTTP_', 'PATH_', 'CONTENT_', 'REMOTE_') ||
                             %w[QUERY_STRING REQUEST_METHOD].include?(key)
                         end
                       })
      end

      error
    end

    def self.catch_and_respond(cgi, &block)
      if error = catch_exceptions(&block)
        status = if error.class <= NotFoundError
                   'NOT_FOUND'
                 elsif error.class <= ForbiddenError
                   'FORBIDDEN'
                 elsif error.class <= HandledError
                   'BAD_REQUEST'
                 else
                   'SERVER_ERROR'
                 end

        cgi.out 'type' => 'text/html',
                'charset' => 'UTF-8',
                'status' => status do
          render 'error.html', error: error
        end
      end
    end
  end
end
