require "minitest/autorun"
require_relative "../../cgi-bin/lib/encoding"

class TestLegacyClientEncoding < Minitest::Test
  def test_empty_env
    encoding = WaybackClassic::LegacyClientEncoding.detect {}

    assert_nil encoding.utf8
    assert_nil encoding.encoding_override
  end

  def test_empty_utf8
    env = { "QUERY_STRING" => "q=foobar&utf8=" }

    encoding = WaybackClassic::LegacyClientEncoding.detect env

    assert_nil encoding.utf8
    assert_nil encoding.encoding_override

    # Updates the env
    assert_equal "q=foobar&utf8=", env["QUERY_STRING"]

    # Keeps encoding the same
    assert_equal "ねこ", encoding.encode("ねこ")

    # Uses curly quotes
    assert_equal "“foo”", encoding.quotify("foo")
  end

  def test_normal_utf8
    env = { "QUERY_STRING" => "q=foobar&utf8=%E2%9C%93" }

    encoding = WaybackClassic::LegacyClientEncoding.detect env

    assert_equal "✓", encoding.utf8
    assert_nil encoding.encoding_override

    # Updates the env
    assert_equal "q=foobar", env["QUERY_STRING"]

    # Keeps encoding the same
    assert_equal "ねこ", encoding.encode("ねこ")

    # Uses curly quotes
    assert_equal "“foo”", encoding.quotify("foo")
  end

  def test_dreampassport3_utf8
    env = { "QUERY_STRING" => "q=foobar&utf8=%EF%BF%BD%13" }

    encoding = WaybackClassic::LegacyClientEncoding.detect env

    assert_equal "\ufffd\x13", encoding.utf8
    assert_equal "Shift_JIS", encoding.encoding_override

    # Updates the env
    assert_equal "q=foobar", env["QUERY_STRING"]

    # Forces the encoding to use JIS
    assert_equal "ねこ".encode("Shift_JIS").force_encoding("UTF-8"), encoding.encode("ねこ")

    # Uses normal quotes
    assert_equal "\"foo\"", encoding.quotify("foo")
  end

  def test_safari_jis_mode_utf8
    env = { "QUERY_STRING" => "q=foobar&utf8=%EF%BF%BD%26%2365533%3B" }

    encoding = WaybackClassic::LegacyClientEncoding.detect env

    assert_equal "\ufffd\x26\x2365533\x3b", encoding.utf8
    assert_equal "Shift_JIS", encoding.encoding_override

    # Updates the env
    assert_equal "q=foobar", env["QUERY_STRING"]

    # Forces the encoding to use JIS
    assert_equal "ねこ".encode("Shift_JIS").force_encoding("UTF-8"), encoding.encode("ねこ")

    # Uses normal quotes
    assert_equal "\"foo\"", encoding.quotify("foo")
  end
end
