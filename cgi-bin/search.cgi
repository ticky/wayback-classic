#!/usr/bin/env ruby

# Wayback Machine Search CGI Script
# ---------------------------------
# Uses the Wayback Machine's undocumented site search API to
# find relevant archived sites for a given set of keywords.
#
# Wayback Classic
# Copyright (C) 2024 Jessica Stokes
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require 'cgi'
require 'json'

require_relative 'lib/encoding'
require_relative 'lib/error_reporting'
require_relative 'lib/permit_world_writable_temp' if ENV["FORCE_WORLD_WRITABLE_TEMP"] == "true"
require_relative 'lib/utils'
require_relative 'lib/web_client'

module WaybackClassic
  module Search
    def self.run
      legacy_encoding = LegacyClientEncoding.detect

      CGI.new.tap do |cgi|
        ErrorReporting.catch_and_respond(cgi) do
          if cgi.params.keys - ["q"] != [] || cgi.params["q"]&.first.nil? || cgi.params["q"]&.first&.empty?
            raise ErrorReporting::BadRequestError.new("A `q` parameter must be supplied, and no other parameters are accepted")
          end

          query = cgi.params["q"].first

          response = begin
                       WebClient.open uri("https://web.archive.org/__wb/search/anchor", q: query), "Referer" => "https://web.archive.org"
                     rescue OpenURI::HTTPError
                       raise ErrorReporting::ServerError.new("Couldn't retrieve results for these keywords")
                     end

          site_results = JSON.parse response.read

          cgi.out "type" => "text/html",
                  "charset" => "UTF-8",
                  "status" => "OK" do
            render "search.html", query: query,
                                  site_results: site_results,
                                  legacy_encoding: legacy_encoding
          end
        end
      end
    end
  end
end

WaybackClassic::Search.run if $PROGRAM_NAME == __FILE__
