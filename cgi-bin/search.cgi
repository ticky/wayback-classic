#!/usr/bin/env ruby

# Wayback Machine Search CGI Script
# ---------------------------------
# Uses the Wayback Machine's undocumented site search API to
# find relevant archived sites for a given set of keywords.

require 'cgi'
require 'erb'
require 'json'
require 'net/http'

cgi = CGI.new

require_relative 'lib/utils'

begin
  if cgi.params.keys != ["q"] || cgi.params["q"].first.empty?
    raise StandardError.new("A query parameter must be provided")
  end

    query = cgi.params["q"].first

  response = Net::HTTP.get_response uri("https://web.archive.org/__wb/search/anchor", q: query)

  unless response.is_a?(Net::HTTPSuccess)
    raise StandardError.new("Couldn't retrieve results for these keywords")
  end

  site_results = JSON.parse response.body

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
