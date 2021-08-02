require 'open-uri'
require_relative 'web_client/cache'

module WaybackClassic
  class WebClient
    USER_AGENT = "wayback-classic.nfshost.com/0.1 (wayback@jessicastokes.net) Ruby/#{RUBY_VERSION}"

    def self.open(uri, options = {})
      options['User-Agent'] = USER_AGENT
      Cache.get(uri) || Cache.put(uri, URI.open(uri, options))
    end
  end
end
