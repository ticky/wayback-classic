#!/usr/bin/env ruby

# Wayback Machine Lookup CGI Script
# ---------------------------------
# Queries the Wayback Machine to determine if the search term is a URL or not,
# then redirects to the appropriate script to show results to the user

require 'cgi'
require 'json'

require_relative 'lib/encoding'
require_relative 'lib/error_reporting'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"
require_relative 'lib/utils'
require_relative 'lib/web_client'

module WaybackClassic
  module Lookup
    def self.run
      legacy_encoding = LegacyClientEncoding.detect

      CGI.new.tap do |cgi|
        ErrorReporting.catch_and_respond(cgi) do
          if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.nil? || cgi.params["q"]&.first&.empty?
            raise ErrorReporting::BadRequestError.new("A `q` parameter must be supplied, and no other parameters are accepted")
          end

          query = cgi.params["q"].first

          response = begin
                       WebClient.open uri("https://web.archive.org/__wb/search/host", q: query)
                     rescue OpenURI::HTTPError
                       raise ErrorReporting::ServerError.new("Couldn't retrieve information for this query or URL")
                     end

          data = JSON.parse response.read

          if data["isUrl"]
            redirect_uri = uri "/cgi-bin/history.cgi", q: query, utf8: legacy_encoding.utf8

            cgi.out "type" => "text/html",
                    "charset" => "UTF-8",
                    "status" => "REDIRECT",
                    "location" => redirect_uri do
              render "redirect.html", redirect_uri: redirect_uri
            end

            return
          end

          redirect_uri = uri "/cgi-bin/search.cgi", q: query, utf8: legacy_encoding.utf8

          cgi.out "type" => "text/html",
                  "charset" => "UTF-8",
                  "status" => "REDIRECT",
                  "location" => redirect_uri do
            render "redirect.html", redirect_uri: redirect_uri
          end
        end
      end
    end
  end
end

WaybackClassic::Lookup.run if $PROGRAM_NAME == __FILE__
