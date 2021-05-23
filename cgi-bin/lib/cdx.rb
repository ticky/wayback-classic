def cdx_objectify(data)
  heading = data[0]
  rows = data[1..-1]

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
