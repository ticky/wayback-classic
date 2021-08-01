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
    PAGE_SIZE = 50

    def self.run
      legacy_encoding = LegacyClientEncoding.detect

      CGI.new.tap do |cgi|
        ErrorReporting.catch_and_respond(cgi) do
          if cgi.params.keys - ["q", "page"] != [] || cgi.params["q"]&.first.nil? || cgi.params["q"]&.first&.empty?
            raise ErrorReporting::BadRequestError.new("A `q` parameter must be supplied, and no other parameters are accepted")
          end

          query = cgi.params["q"]&.first
          page = cgi.params["page"]&.first&.to_i || 1

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

          total_count = cdx_results.length
          page_count = (total_count.to_f / PAGE_SIZE).ceil

          cdx_results = cdx_results.slice(page - 1 * PAGE_SIZE, PAGE_SIZE)

          cgi.out "type" => "text/html",
                  "charset" => "UTF-8",
                  "status" => "OK" do
            render "sitemap.html",
                   query: query,
                   total_count: total_count,
                   page: page || 1,
                   page_count: page_count,
                   cdx_results: cdx_results,
                   legacy_encoding: legacy_encoding
          end
        end
      end
    end
  end
end

WaybackClassic::Sitemap.run if $PROGRAM_NAME == __FILE__
