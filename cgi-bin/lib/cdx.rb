require 'date'
require 'json'

module WaybackClassic
  module CDX
    def self.objectify(data)
      data = JSON.parse data if data.is_a? String

      heading = data[0]
      rows = data[1..-1] || []

      rows.map do |row|
        hash_row = {}

        heading.each_with_index do |item, index|
          hash_row['datetime'] = parse_date row[index] if item == 'timestamp'
          hash_row['enddatetime'] = parse_date row[index] if item == 'endtimestamp'

          hash_row[item] = row[index]
        end

        hash_row
      end
    end

    def self.parse_date(date)
      # For some reason, the CDX API sometimes returns dates from the 0th month...
      if date[4,2] == '00'
        date[4,2] = '12'
        date[0,4] = (date[0,4].to_i - 1).to_s.rjust(4, '0')
      end

      # ...and hours greater than 23
      if date[8,2].to_i > 23
        date[8,2] = (date[8,2].to_i - 24).to_s.rjust(2, '0')
        date[6,2] = (date[6,2].to_i + 1).to_s.rjust(2, '0')
      end

      DateTime.parse date
    end
  end
end
