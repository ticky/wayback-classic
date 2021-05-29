require 'date'
require 'json'

class CDX
  def self.objectify(data)
    data = JSON.parse data if data.is_a? String

    heading = data[0]
    rows = data[1..-1] || []

    rows.map do |row|
      hash_row = {}

      heading.each_with_index do |item, index|
        if item == "timestamp"
          hash_row["datetime"] = DateTime.parse row[index]
        end

        hash_row[item] = row[index]
      end

      hash_row
    end
  end
end
