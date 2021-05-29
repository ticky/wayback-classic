#!/usr/bin/env ruby

# Wayback Machine History CGI Script
# ----------------------------------
# Uses the Wayback Machine's CDX API to retrieve
# a list of snapshots for the given URL.

require 'cgi'

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

    if date == "latest" || date == "earliest"
      limit = if date == "latest"
                -1
              elsif date == "earliest"
                1
              end

      response = begin
                   WebClient.open uri("http://web.archive.org/cdx/search/cdx",
                                      url: query,
                                      output: "json",
                                      limit: limit)
                 rescue OpenURI::HTTPError
                   raise ErrorReporting::ServerError.new("Couldn't #{date} snapshot for this URL")
                 end

      cdx_results = CDX.objectify response.read

      if cdx_results.any?
        scheme = (ENV["REQUEST_SCHEME"] || ENV["REQUEST_URI"] || "http").split(":").first

        redirect_uri = "#{scheme}://web.archive.org/web/#{cdx_results.first["timestamp"]}if_/#{cdx_results.first["original"]}"

        cgi.out "type" => "text/html",
                "charset" => "UTF-8",
                "status" => "REDIRECT",
                "location" => redirect_uri do
          render "redirect.html", redirect_uri: redirect_uri
        end

        return
      end
    end

    date_index = begin
      response = WebClient.open uri("http://web.archive.org/cdx/search/cdx",
                                    url: query,
                                    output: "json",
                                    collapse: "timestamp:6")

      CDX.objectify(response.read).group_by { |index_item| index_item["datetime"].year }
    rescue OpenURI::HTTPError
      raise ErrorReporting::ServerError.new("Couldn't retrieve date index for this URL")
    end

    if date.nil? || date.empty? || date.length < 6
      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "OK" do
        render "history/index.html",
               query: query,
               date_index: date_index
      end

      return
    end

    response = begin
                 WebClient.open uri("http://web.archive.org/cdx/search/cdx",
                                    url: query,
                                    output: "json",
                                    from: date,
                                    to: date,
                                    collapse: "digest")
               rescue OpenURI::HTTPError
                 raise ErrorReporting::ServerError.new("Couldn't retrieve monthly history for this URL")
               end

    cdx_results = CDX.objectify response.read

    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "OK" do
      render "history/calendar.html",
             query: query,
             date_index: date_index,
             date: date,
             cdx_results: cdx_results
    end
  end
end
