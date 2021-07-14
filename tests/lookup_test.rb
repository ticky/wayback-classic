require 'minitest/autorun'
require 'open3'
require 'webrick/cookie'
require 'webrick/httpresponse'
require 'webrick/httpstatus'
require 'webrick/httputils'

class TestLookup < Minitest::Test
  # based on https://github.com/ruby/webrick/blob/3515081a51b91b730267ba2b224039ecfbf8bd7b/lib/webrick/httpservlet/cgihandler.rb#L94-L118
  def parse_http_response(data, res=WEBrick::HTTPResponse.new(HTTPVersion: "1.1"))
    raw_header, body = data.split(/^[\xd\xa]+/, 2)
    raise WEBrick::HTTPStatus::InternalServerError,
      "Premature end of script headers: #{@script_filename}" if body.nil?

    begin
      header = WEBrick::HTTPUtils::parse_header(raw_header)
      if /^(\d+)/ =~ header['status'][0]
        res.status = $1.to_i
        header.delete('status')
      end
      if header.has_key?('location')
        # RFC 3875 6.2.3, 6.2.4
        res.status = 302 unless (300...400) === res.status
      end
      if header.has_key?('set-cookie')
        header['set-cookie'].each{|k|
          res.cookies << WEBrick::Cookie.parse_set_cookie(k)
        }
        header.delete('set-cookie')
      end
      header.each{|key, val| res[key] = val.join(", ") }
    rescue => ex
      raise WEBrick::HTTPStatus::InternalServerError, ex.message
    end
    res.body = body

    res
  end

  def test_lookup
    out, err, status = Open3.capture3({ "REQUEST_METHOD" => "GET",
                                        "QUERY_STRING" => "q=" },
                                      "cgi-bin/lookup.cgi",
                                      chdir: File.expand_path("../..", __FILE__))

    assert_equal "", err
    assert_equal 0, status
    assert_equal <<~HTTP, out
      Status: 400 Bad Request\r
      Content-Type: text/html; charset=UTF-8\r
      Content-Length: 847\r
      \r
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
      "http://www.w3.org/TR/html4/loose.dtd">
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1.0">
          <title>Wayback Classic - Error</title>
        </head>
        <body background="/images/background@0.5x.gif">
          <center>
            <h1>Error</h1>
          
            <p>A `q` parameter must be supplied, and no other parameters are accepted</p>
            <p>Want to try again?</p>
          
            <form action="/cgi-bin/lookup.cgi" method="get">
              <label>URL or keywords: <input type="text" name="q"></label>
              <input type="hidden" name="utf8" value="✓">
              <input type="submit" value="Look Up">
            </form>
            <hr>
            <a href="/">wayback-classic</a>
          </center>
        </body>
      </html>
    HTTP

    response = parse_http_response(out)

    assert_equal 400, response.status
  end
end
