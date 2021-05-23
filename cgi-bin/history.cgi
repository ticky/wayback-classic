#!/usr/bin/env ruby

# Wayback Machine History CGI Script
# ----------------------------------
# Uses the Wayback Machine's CDX API to retrieve
# a list of snapshots for the given URL.

require 'cgi'
require 'date'
require 'json'
require 'net/http'

require_relative 'lib/cdx'
require_relative 'lib/utils'

CGI.new.tap do |cgi|
  if cgi.params.keys - ["q", "date"] != [] || cgi.params["q"]&.first.empty?
    raise StandardError.new("A query parameter must be provided")
  end

  query = cgi.params["q"]&.first
  date = cgi.params["date"]&.first

  date_index = begin
    # TODO: Cache this
    response = Net::HTTP.get_response uri("http://web.archive.org/cdx/search/cdx",
                                          url: query,
                                          output: "json",
                                          collapse: "timestamp:6")

    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError.new("Couldn't retrieve page history for this URL: #{response.body}")
    end

    cdx_objectify(JSON.parse(response.body)).group_by { |index_item| index_item["datetime"].year }
  end

  # cgi.out("text/plain") { JSON.dump date_index }
  # exit

  if date.nil? || date.empty?
    # List applicable years

    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "OK" do
      render "history/index.html", query: query, date_index: date_index
    end
  else
    # TODO: Use this result to create a list of years,
    # and based on the presence of a year parameter,
    # generate a yearly calendar view
    response = Net::HTTP.get_response uri("http://web.archive.org/cdx/search/cdx",
                                          url: query,
                                          output: "json",
                                          from: date,
                                          to: date,
                                          collapse: "digest")

    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError.new("Couldn't retrieve page history for this URL: #{response.body}")
    end

    cdx_results = cdx_objectify JSON.parse(response.body)

    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "OK" do
      render "history/calendar.html", query: query, date_index: date_index, date: date, cdx_results: cdx_results
    end
  end
rescue => error
  cgi.out "type" => "text/html",
          "charset" => "UTF-8",
          "status" => "BAD_REQUEST" do
    render "error.html", error: error
  end
end
