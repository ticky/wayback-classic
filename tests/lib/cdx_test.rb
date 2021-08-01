require 'minitest/autorun'
require_relative '../../cgi-bin/lib/cdx'

class TestCDX < Minitest::Test
  def test_objectify_string
    expected = [
      { 'urlkey' => 'jp,ne,dricas,pso)/',
        'datetime' => DateTime.iso8601('2001-02-02T05:41:00+00:00'),
        'timestamp' => '20010202054100',
        'original' => 'http://pso.dricas.ne.jp:80/',
        'mimetype' => 'text/html',
        'statuscode' => '200',
        'digest' => 'MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN',
        'length' => '1045' },
      { 'urlkey' => 'jp,ne,dricas,pso)/',
        'datetime' => DateTime.iso8601('2001-02-24T20:46:16+00:00'),
        'timestamp' => '20010224204616',
        'original' => 'http://pso.dricas.ne.jp:80/',
        'mimetype' => 'text/html',
        'statuscode' => '200',
        'digest' => 'HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB',
        'length' => '1048' }
    ]

    object = WaybackClassic::CDX.objectify(<<~JSON)
      [["urlkey","timestamp","original","mimetype","statuscode","digest","length"],
      ["jp,ne,dricas,pso)/", "20010202054100", "http://pso.dricas.ne.jp:80/", "text/html", "200", "MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN", "1045"],
      ["jp,ne,dricas,pso)/", "20010224204616", "http://pso.dricas.ne.jp:80/", "text/html", "200", "HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB", "1048"]]
    JSON

    assert_equal expected, object
  end

  def test_objectify_array
    expected = [
      { 'urlkey' => 'jp,ne,dricas,pso)/',
        'datetime' => DateTime.iso8601('2001-02-02T05:41:00+00:00'),
        'timestamp' => '20010202054100',
        'original' => 'http://pso.dricas.ne.jp:80/',
        'mimetype' => 'text/html',
        'statuscode' => '200',
        'digest' => 'MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN',
        'length' => '1045' },
      { 'urlkey' => 'jp,ne,dricas,pso)/',
        'datetime' => DateTime.iso8601('2001-02-24T20:46:16+00:00'),
        'timestamp' => '20010224204616',
        'original' => 'http://pso.dricas.ne.jp:80/',
        'mimetype' => 'text/html',
        'statuscode' => '200',
        'digest' => 'HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB',
        'length' => '1048' }
    ]

    object = WaybackClassic::CDX.objectify(
      [%w[urlkey timestamp original mimetype statuscode digest length],
       ['jp,ne,dricas,pso)/', '20010202054100', 'http://pso.dricas.ne.jp:80/', 'text/html', '200',
        'MPPCZOZMMLAPX7DKSDGABNOPXSHEOJUN', '1045'],
       ['jp,ne,dricas,pso)/', '20010224204616', 'http://pso.dricas.ne.jp:80/', 'text/html', '200',
        'HL36R4XZNBVYKLXJ5DC2NNIQHXI4LKFB', '1048']]
    )

    assert_equal expected, object
  end

  def test_objectify_custom_columns
    expected = [
      { 'original' => 'http://www.dricas.ne.jp:80/',
        'mimetype' => 'text/html',
        'datetime' => DateTime.iso8601('1999-10-05T20:19:15+00:00'),
        'timestamp' => '19991005201915',
        'enddatetime' => DateTime.iso8601('2016-05-25T05:06:27+00:00'),
        'endtimestamp' => '20160525050627',
        'groupcount' => '127',
        'uniqcount' => '11' },
      { 'original' => 'http://www.dricas.ne.jp:80/atbarai',
        'mimetype' => 'text/html',
        'datetime' => DateTime.iso8601('2001-02-19T15:28:51+00:00'),
        'timestamp' => '20010219152851',
        'enddatetime' => DateTime.iso8601('2007-08-20T00:40:56+00:00'),
        'endtimestamp' => '20070820004056',
        'groupcount' => '19',
        'uniqcount' => '2' }
    ]

    object = WaybackClassic::CDX.objectify(
      [["original", "mimetype", "timestamp", "endtimestamp", "groupcount", "uniqcount"],
      ["http://www.dricas.ne.jp:80/", "text/html", "19991005201915", "20160525050627", "127", "11"],
      ["http://www.dricas.ne.jp:80/atbarai", "text/html", "20010219152851", "20070820004056", "19", "2"]]
    )

    assert_equal expected, object
  end

  def test_objectify_header_only
    object = WaybackClassic::CDX.objectify(<<~JSON)
      [["urlkey","timestamp","original","mimetype","statuscode","digest","length"]]
    JSON

    assert_equal [], object
  end

  def test_objectify_empty
    assert_equal [], WaybackClassic::CDX.objectify([])
  end
end
