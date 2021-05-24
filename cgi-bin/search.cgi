#!/usr/bin/env ruby

# Wayback Machine Search CGI Script
# ---------------------------------
# Uses the Wayback Machine's undocumented site search API to
# find relevant archived sites for a given set of keywords.

require 'cgi'
require 'erb'
require 'json'
require 'open-uri'

require_relative 'lib/encoding'
require_relative 'lib/utils'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"

utf8, encoding_override = detect_client_encoding

CGI.new.tap do |cgi|
  if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.empty?
    raise StandardError.new("A `q` parameter must be supplied, and no other parameters are accepted")
  end

  query = cgi.params["q"].first

  response = URI.open uri("https://web.archive.org/__wb/search/anchor", q: query),
                      "User-Agent" => USER_AGENT

  unless response.status[0][0] == "2"
    raise StandardError.new("Couldn't retrieve results for these keywords")
  end

  site_results = JSON.parse response.read

  cgi.out "type" => "text/html",
          "charset" => "UTF-8",
          "status" => "OK" do
    render "search.html", query: query, site_results: site_results
  end
rescue => error
  cgi.out "type" => "text/html",
          "charset" => "UTF-8",
          "status" => "BAD_REQUEST" do
    render "error.html", error: error
  end
end
