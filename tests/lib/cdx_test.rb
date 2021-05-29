require "minitest/autorun"
require_relative "../../cgi-bin/lib/cdx"

class TestCDX < Minitest::Test
  def test_objectify_string
    expected = [
      { "urlkey" => "jp,ne,dricas,pso)/",
        "datetime" => DateTime.iso8601("2001-02-02T05:41:00+00:00"),
        "timestamp" => "20010202054100",
        "original" => "http://pso.dricas.ne.jp:80/",
        "mimetype" => "text/html",
        "statuscode" => "200",
        "digest" => "MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN",
        "length" => "1045" },
      { "urlkey" => "jp,ne,dricas,pso)/",
        "datetime" => DateTime.iso8601("2001-02-24T20:46:16+00:00"),
        "timestamp" => "20010224204616",
        "original" => "http://pso.dricas.ne.jp:80/",
        "mimetype" => "text/html",
        "statuscode" => "200",
        "digest" => "HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB",
        "length" => "1048" }
    ]

    object = CDX.objectify(<<~JSON)
      [["urlkey","timestamp","original","mimetype","statuscode","digest","length"],
      ["jp,ne,dricas,pso)/", "20010202054100", "http://pso.dricas.ne.jp:80/", "text/html", "200", "MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN", "1045"],
      ["jp,ne,dricas,pso)/", "20010224204616", "http://pso.dricas.ne.jp:80/", "text/html", "200", "HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB", "1048"]]
    JSON

    assert_equal expected, object
  end

  def test_objectify_array
    expected = [
      { "urlkey" => "jp,ne,dricas,pso)/",
        "datetime" => DateTime.iso8601("2001-02-02T05:41:00+00:00"),
        "timestamp" => "20010202054100",
        "original" => "http://pso.dricas.ne.jp:80/",
        "mimetype" => "text/html",
        "statuscode" => "200",
        "digest" => "MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN",
        "length" => "1045" },
      { "urlkey" => "jp,ne,dricas,pso)/",
        "datetime" => DateTime.iso8601("2001-02-24T20:46:16+00:00"),
        "timestamp" => "20010224204616",
        "original" => "http://pso.dricas.ne.jp:80/",
        "mimetype" => "text/html",
        "statuscode" => "200",
        "digest" => "HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB",
        "length" => "1048" }
    ]

    object = CDX.objectify(
      [["urlkey", "timestamp", "original", "mimetype", "statuscode", "digest", "length"],
       ["jp,ne,dricas,pso)/", "20010202054100", "http://pso.dricas.ne.jp:80/", "text/html", "200",
        "MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN", "1045"],
       ["jp,ne,dricas,pso)/", "20010224204616", "http://pso.dricas.ne.jp:80/", "text/html", "200",
        "HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB", "1048"]]
    )

    assert_equal expected, object
  end

  def test_objectify_header_only
    object = CDX.objectify(<<~JSON)
      [["urlkey","timestamp","original","mimetype","statuscode","digest","length"]]
    JSON

    assert_equal [], object
  end

  def test_objectify_empty
    assert_equal [], CDX.objectify([])
  end
end
