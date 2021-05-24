#!/usr/bin/env ruby

# Wayback Machine Lookup CGI Script
# ---------------------------------
# Queries the Wayback Machine to determine if the search term is a URL or not,
# then redirects to the appropriate script to show results to the user

require 'cgi'
require 'erb'
require 'json'
require 'open-uri'

require_relative 'lib/error_reporting'
require_relative 'lib/encoding'
require_relative 'lib/utils'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"

utf8, encoding_override = detect_client_encoding

CGI.new.tap do |cgi|
  catch_exceptions_and_respond(cgi) do
    if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.empty?
      raise StandardError.new("A `q` parameter must be supplied, and no other parameters are accepted")
    end

    query = cgi.params["q"].first

    response = URI.open uri("https://web.archive.org/__wb/search/host", q: query),
                        "User-Agent" => USER_AGENT

    unless response.status[0][0] == "2"
      raise StandardError.new("Couldn't retrieve information about this URL")
    end

    data = JSON.parse response.read

    if data["isUrl"]
      redirect_uri = uri "/cgi-bin/history.cgi", q: query, utf8: utf8

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "REDIRECT",
              "location" => redirect_uri do
        render "redirect.html", redirect_uri: redirect_uri
      end
    else
      redirect_uri = uri "/cgi-bin/search.cgi", q: query, utf8: utf8

      cgi.out "type" => "text/html",
              "charset" => "UTF-8",
              "status" => "REDIRECT",
              "location" => redirect_uri do
        render "redirect.html", redirect_uri: redirect_uri
      end
    end
  end
end
