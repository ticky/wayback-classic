#!/usr/bin/env ruby

# Wayback Machine History CGI Script
# ----------------------------------
# Uses the Wayback Machine's CDX API to retrieve
# a list of snapshots for the given URL.

require 'cgi'
require 'date'
require 'json'
require 'open-uri'

require_relative 'lib/error_reporting'
require_relative 'lib/cdx'
require_relative 'lib/encoding'
require_relative 'lib/utils'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"

utf8, encoding_override = detect_client_encoding

CGI.new.tap do |cgi|
  catch_exceptions_and_respond(cgi) do
    if cgi.params.keys - ["q", "date"] != [] || cgi.params["q"]&.first.empty?
      raise StandardError.new("A query parameter must be provided")
    end

    query = cgi.params["q"]&.first
    date = cgi.params["date"]&.first

    date_index = begin
      # TODO: Cache this
      response = URI.open uri("http://web.archive.org/cdx/search/cdx",
                              url: query,
                              output: "json",
                              collapse: "timestamp:6"),
                          "User-Agent" => USER_AGENT

      unless response.status[0][0] == "2"
        raise StandardError.new("Couldn't retrieve page history for this URL: #{response.read}")
      end

      cdx_objectify(JSON.parse(response.read)).group_by { |index_item| index_item["datetime"].year }
    end

    if date.nil? || date.empty? || date.length < 6
      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "OK" do
        render "history/index.html", query: query, date_index: date_index
      end
    else
      response = URI.open uri("http://web.archive.org/cdx/search/cdx",
                              url: query,
                              output: "json",
                              from: date,
                              to: date,
                              collapse: "digest"),
                          "User-Agent" => USER_AGENT

      unless response.status[0][0] == "2"
        raise StandardError.new("Couldn't retrieve page history for this URL: #{response.read}")
      end

      cdx_results = cdx_objectify JSON.parse(response.read)

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "OK" do
        render "history/calendar.html", query: query, date_index: date_index, date: date, cdx_results: cdx_results
      end
    end
  end
end
