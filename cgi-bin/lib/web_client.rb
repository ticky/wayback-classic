require 'open-uri'
require_relative 'error_reporting'
require_relative 'web_client/cache'

module WaybackClassic
  class WebClient
    USER_AGENT = "wayback-classic.nfshost.com/0.1 (wayback@jessicastokes.net) Ruby/#{RUBY_VERSION}"

    class ForbiddenError < ErrorReporting::ForbiddenError; end

    class NotFoundError < ErrorReporting::NotFoundError; end

    def self.open(uri, options = {})
      options['User-Agent'] = USER_AGENT
      Cache.get(uri) || Cache.put(uri, URI.open(uri, options))
    rescue OpenURI::HTTPError => error
      case error.io.status[0]
      when "403"
        raise ForbiddenError.new("Got a #{error.io.status.join(' ')} response while retrieving data. This may mean the URL has been excluded from the Wayback Machine.")
      when "404"
        raise NotFoundError.new("Got a #{error.io.status.join(' ')} response while retrieving data. This may mean the URL has not been archived by the Wayback Machine.")
      else
        raise error
      end
    end
  end
end
