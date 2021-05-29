#!/usr/bin/env ruby

# Wayback Machine History CGI Script
# ----------------------------------
# Uses the Wayback Machine's CDX API to retrieve
# a list of snapshots for the given URL.

require 'cgi'
require 'date'
require 'json'

require_relative 'lib/cdx'
require_relative 'lib/encoding'
require_relative 'lib/error_reporting'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"
require_relative 'lib/utils'
require_relative 'lib/web_client'

legacy_encoding = LegacyClientEncoding.detect

CGI.new.tap do |cgi|
  ErrorReporting.catch_and_respond(cgi) do
    if cgi.params.keys - ["q", "date"] != [] || cgi.params["q"]&.first.empty?
      raise ErrorReporting::BadRequestError.new("A query parameter must be provided")
    end

    query = cgi.params["q"]&.first
    date = cgi.params["date"]&.first

    date_index = begin
      response = WebClient.open uri("http://web.archive.org/cdx/search/cdx",
                                    url: query,
                                    output: "json",
                                    collapse: "timestamp:6")

      # TODO: This doesn't actually work with this HTTP client
      unless response.status[0][0] == "2"
        raise ErrorReporting::ServerError.new("Couldn't retrieve page history for this URL: #{response.read}")
      end

      CDX.objectify(JSON.parse(response.read)).group_by { |index_item| index_item["datetime"].year }
    end

    if date.nil? || date.empty? || date.length < 6
      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "OK" do
        render "history/index.html", query: query, date_index: date_index
      end
    else
      response = WebClient.open uri("http://web.archive.org/cdx/search/cdx",
                                    url: query,
                                    output: "json",
                                    from: date,
                                    to: date,
                                    collapse: "digest")

      # TODO: This doesn't actually work with this HTTP client
      unless response.status[0][0] == "2"
        raise ErrorReporting::ServerError.new("Couldn't retrieve page history for this URL: #{response.read}")
      end

      cdx_results = CDX.objectify JSON.parse(response.read)

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "OK" do
        render "history/calendar.html", query: query, date_index: date_index, date: date, cdx_results: cdx_results
      end
    end
  end
end
