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
          if cgi.params.keys - ["q", "page", "filter"] != [] || cgi.params["q"]&.first.nil? || cgi.params["q"]&.first&.empty?
            raise ErrorReporting::BadRequestError.new("A `q` parameter must be supplied, and no other parameters are accepted")
          end

          query = cgi.params["q"]&.first
          page = cgi.params["page"]&.first&.to_i || 1
          filter = cgi.params["filter"]&.first

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

          # Hold onto the count of results for the entire thing
          total_count = cdx_results.length

          if filter
            cdx_results = cdx_results.select do |cdx_result|
              cdx_result["mimetype"].downcase.include?(filter.downcase) || cdx_result["original"].downcase.include?(filter.downcase)
            end
          end

          scoped_count = cdx_results.length
          page_count = (scoped_count.to_f / PAGE_SIZE).ceil
          page_count = 1 if page_count == 0

          cdx_results = cdx_results.slice((page - 1) * PAGE_SIZE, PAGE_SIZE)

          cgi.out "type" => "text/html",
                  "charset" => "UTF-8",
                  "status" => "OK" do
            render "sitemap.html",
                   query: query,
                   filter: filter,
                   total_count: total_count,
                   scoped_count: scoped_count,
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
