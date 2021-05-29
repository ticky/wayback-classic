#!/usr/bin/env ruby

# Wayback Machine Search CGI Script
# ---------------------------------
# Uses the Wayback Machine's undocumented site search API to
# find relevant archived sites for a given set of keywords.

require 'cgi'
require 'json'

require_relative 'lib/encoding'
require_relative 'lib/error_reporting'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"
require_relative 'lib/utils'
require_relative 'lib/web_client'

legacy_encoding = LegacyClientEncoding.detect

CGI.new.tap do |cgi|
  ErrorReporting.catch_and_respond(cgi) do
    if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.empty?
      raise ErrorReporting::BadRequestError.new("A `q` parameter must be supplied, and no other parameters are accepted")
    end

    query = cgi.params["q"].first

    response = begin
                 WebClient.open uri("https://web.archive.org/__wb/search/anchor", q: query)
               rescue OpenURI::HTTPError
                 raise ErrorReporting::ServerError.new("Couldn't retrieve results for these keywords")
               end

    site_results = JSON.parse response.read

    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "OK" do
      render "search.html", query: query, site_results: site_results
    end
  end
end
