#!/usr/bin/env ruby

# Wayback Machine Lookup CGI Script
# ---------------------------------
# Queries the Wayback Machine to determine if the search term is a URL or not,
# then redirects to the appropriate script to show results to the user

require 'cgi'
require 'erb'
require 'json'
require 'net/http'

require_relative 'lib/utils'

CGI.new.tap do |cgi|
  if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.empty?
    raise StandardError.new("A `q` parameter must be supplied, and no other parameters are accepted")
  end

  query = cgi.params["q"].first

  response = Net::HTTP.get_response uri("https://web.archive.org/__wb/search/host", q: query)

  unless response.is_a?(Net::HTTPSuccess)
    raise StandardError.new("Couldn't retrieve information about this URL")
  end

  data = JSON.parse response.body

  if data["isUrl"]
    # Redirect to History page
    redirect_uri = uri "history.cgi", q: query

    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "REDIRECT",
            "location" => redirect_uri do
      render "redirect.html", redirect_uri: redirect_uri
    end
  else
    # Redirect to Search page
    redirect_uri = uri "search.cgi", q: query

    cgi.out "type" => "text/html",
            "charset" => "UTF-8",
            "status" => "REDIRECT",
            "location" => redirect_uri do
      render "redirect.html", redirect_uri: redirect_uri
    end
  end
rescue => error
  cgi.out "type" => "text/html",
          "charset" => "UTF-8",
          "status" => "BAD_REQUEST" do
    render "error.html", error: error
  end
end
