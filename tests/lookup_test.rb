require 'minitest/autorun'
require 'open3'
require 'webrick/cookie'
require 'webrick/httpresponse'
require 'webrick/httpstatus'
require 'webrick/httputils'
require_relative 'capybara_test_case'

class TestLookup < CapybaraTestCase
  def test_keywords
    visit "/cgi-bin/lookup.cgi?q=apple&utf8=%E2%9C%93"
    assert_current_path "/cgi-bin/search.cgi?q=apple&utf8=%E2%9C%93"

    assert_title "Wayback Classic - Searching for “apple”"
    assert_text "Search results for “apple”"
  end

  def test_empty_parameters
    visit "/cgi-bin/lookup.cgi?q="
    assert_current_path "/cgi-bin/lookup.cgi?q="

    assert_title "Wayback Classic - Error"
    assert_text "A `q` parameter must be supplied, and no other parameters are accepted"
  end

  def test_no_parameters
    visit "/cgi-bin/lookup.cgi"
    assert_current_path "/cgi-bin/lookup.cgi" # WTF?

    assert_title "Wayback Classic - Error"
    assert_text "A `q` parameter must be supplied, and no other parameters are accepted"
  end

  def test_invalid_parameters
    visit "/cgi-bin/lookup.cgi?q=twitter&utm_medium=evil"
    assert_current_path "/cgi-bin/lookup.cgi?q=twitter&utm_medium=evil"

    assert_title "Wayback Classic - Error"
    assert_text "A `q` parameter must be supplied, and no other parameters are accepted"
  end
end
