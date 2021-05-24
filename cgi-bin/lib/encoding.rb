def detect_client_encoding
  utf8 = nil

  query = URI.decode_www_form(ENV["QUERY_STRING"]).to_h

  if query["utf8"]
    utf8 = query["utf8"]
    query.delete("utf8")
  end

  ENV["QUERY_STRING"] = URI.encode_www_form query

  encoding_override = if utf8 != nil
                        utf8_canary = utf8.split('').map(&:ord)
                        # Note: UTF-8 would be [0x2713]
                        case utf8_canary
                        when [0xfffd, 0x26, 0x23, 0x36, 0x35, 0x35, 0x33, 0x33, 0x3b] # Safari forced to Shift_JIS mode
                        when [0xfffd, 0x13] # Dream Passport 3
                          "Shift_JIS" # or GB 2312
                        # when [0x26, 0x23, 0x36, 0x35, 0x35, 0x33, 0x33, 0x3b, 0x26, 0x23, 0x36, 0x35, 0x35, 0x33, 0x33, 0x3b, 0x26, 0x23, 0x36, 0x35, 0x35, 0x33, 0x33, 0x3b]
                        #   "ISO-2022-JP"
                        # when [0x26, 0x23, 0x36, 0x35, 0x35, 0x33, 0x33, 0x3b, 0x26, 0x23, 0x36, 0x35, 0x35, 0x33, 0x33, 0x3b]
                        #   "EUC-JP" # or Big5, or Korean Windows
                        # when [0x2704, 0x31, 0xfffd, 0x37]
                        #   "GB 18030" # or ISO Latin2
                        end
                      end

  [utf8, encoding_override]
end