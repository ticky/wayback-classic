#!/usr/bin/env ruby

# Wayback Machine Site Map CGI Script
# -----------------------------------
# Uses the Wayback Machine's CDX API to retrieve a
# list of captured URLs under the given wildcard URL.

require 'cgi'

require_relative 'lib/cdx'
require_relative 'lib/encoding'
require_relative 'lib/error_reporting'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"
require_relative 'lib/utils'
require_relative 'lib/web_client'

module WaybackClassic
  module Sitemap
    def self.run
      legacy_encoding = LegacyClientEncoding.detect

      CGI.new.tap do |cgi|
        ErrorReporting.catch_and_respond(cgi) do
          if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.nil? || cgi.params["q"]&.first&.empty?
            raise ErrorReporting::BadRequestError.new("A `q` parameter must be supplied, and no other parameters are accepted")
          end

          query = cgi.params["q"]&.first

          response = begin
                       WebClient.open uri("http://web.archive.org/cdx/search/cdx",
                                          url: query,
                                          output: "json",
                                          collapse: "urlkey",
                                          fl: "original,mimetype,timestamp,endtimestamp,groupcount,uniqcount",
                                          filter: "!statuscode:[45]..")
                     rescue OpenURI::HTTPError
                       raise ErrorReporting::ServerError.new("Couldn't retrieve captured URLs for this wildcard URL")
                     end

          cdx_results = CDX.objectify response.read

          cgi.out "type" => "text/html",
                  "charset" => "UTF-8",
                  "status" => "OK" do
            render "sitemap.html",
                   query: query,
                   cdx_results: cdx_results,
                   legacy_encoding: legacy_encoding
          end
        end
      end
    end
  end
end

WaybackClassic::Sitemap.run if $PROGRAM_NAME == __FILE__
