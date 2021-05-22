#!/usr/bin/env ruby

# Wayback Machine History CGI Script
# ----------------------------------
# Uses the Wayback Machine's CDX API to retrieve
# a list of snapshots for the given URL.

require 'cgi'
require 'date'
require 'json'
require 'net/http'

cgi = CGI.new

require_relative 'lib/utils'

begin
  if cgi.params.keys != ["q"] || cgi.params["q"].first.empty?
    raise StandardError.new("A query parameter must be provided")
  end

  query = cgi.params["q"].first

  response = Net::HTTP.get_response uri("http://web.archive.org/cdx/search/cdx",
                                        url: query,
                                        output: "json",
                                        collapse: ["digest", "timestamp:6"])

  unless response.is_a?(Net::HTTPSuccess)
    raise StandardError.new("Couldn't retrieve page history for this URL: #{response}")
  end

  data = JSON.parse response.body

  heading = data[0]
  rows = data[1..-1]

  cdx_results = rows.map do |row|
    hash_row = {}
    
    heading.each_with_index do |item, index|
      if item == "timestamp"
        hash_row["datetime"] = DateTime.parse row[index]
      end
      
      hash_row[item] = row[index]
    end
    
    hash_row
  end

  cgi.out "type" => "text/html",
      "charset" => "UTF-8",
      "status" => "OK" do
    render "history.html", query: query, cdx_results: cdx_results
  end
rescue => error
  cgi.out "type" => "text/html",
      "charset" => "UTF-8",
      "status" => "BAD_REQUEST" do
    render "error.html", error: error
  end
end
