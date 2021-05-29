#!/usr/bin/env ruby

# Wayback Machine Lookup CGI Script
# ---------------------------------
# Queries the Wayback Machine to determine if the search term is a URL or not,
# then redirects to the appropriate script to show results to the user

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

    response = WebClient.open uri("https://web.archive.org/__wb/search/host", q: query)

    # TODO: This doesn't actually work with this HTTP client
    unless response.status[0][0] == "2"
      raise ErrorReporting::ServerError.new("Couldn't retrieve information about this URL")
    end

    data = JSON.parse response.read

    if data["isUrl"]
      redirect_uri = uri "/cgi-bin/history.cgi", q: query, utf8: legacy_encoding.utf8

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "REDIRECT",
              "location" => redirect_uri do
        render "redirect.html", redirect_uri: redirect_uri
      end
    else
      redirect_uri = uri "/cgi-bin/search.cgi", q: query, utf8: legacy_encoding.utf8

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "REDIRECT",
              "location" => redirect_uri do
        render "redirect.html", redirect_uri: redirect_uri
      end
    end
  end
end
