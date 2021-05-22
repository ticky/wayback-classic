class WaybackController < ApplicationController
  def index
    query = wayback_params["q"]
    
    if query.present?
      uri = URI("https://web.archive.org/__wb/search/host")
      uri.query = URI.encode_www_form q: query
      
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse response.body
        if data["isUrl"]
          uri = URI("http://web.archive.org/cdx/search/cdx")
          uri.query = URI.encode_www_form url: query, output: "json", limit: 100
          
          response = Net::HTTP.get_response(uri)
          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse response.body
            
            heading = data[0]
            rows = data[1..-1]
            
            @cdx_results = rows.map do |row|
              hash_row = {}
              
              heading.each_with_index do |item, index|
                if item == "timestamp"
                  hash_row["datetime"] = DateTime.parse row[index]
                end
                
                hash_row[item] = row[index]
              end
              
              hash_row
            end
          else
            flash[:error] = response.error
          end
        else
          uri = URI("https://web.archive.org/__wb/search/anchor")
          uri.query = URI.encode_www_form q: query
          
          response = Net::HTTP.get_response(uri)
          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse response.body
            @site_results = data
          else
            flash[:error] = response.error
          end
        end
      else
        flash[:error] = response.error
      end
    end
  end
  
  private
  
  def wayback_params
    params.permit(:q)
  end
end
