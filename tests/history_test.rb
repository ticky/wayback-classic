require 'minitest/autorun'
require 'webmock/minitest'
require_relative 'capybara_test_case'
require_relative '../cgi-bin/lib/web_client/cache'

class TestHistory < CapybaraTestCase
  def setup
    super
    # Force the WebClient cache to always be empty
    WaybackClassic::WebClient::Cache.enabled = false
  end

  def teardown
    super
    WaybackClassic::WebClient::Cache.enabled = true
  end

  def test_history
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/history.cgi?q=http%3A%2F%2Fapple.com%2F&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/history.cgi?q=http%3A%2F%2Fapple.com%2F&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Date index for URL “http://apple.com/”'
      assert_text 'Date index for URL “http://apple.com/”'
      assert_link 'October', href: 'history.cgi?q=http%3A%2F%2Fapple.com%2F&date=199610&utf8=%E2%9C%93'
      assert_link 'December', href: 'history.cgi?q=http%3A%2F%2Fapple.com%2F&date=199612&utf8=%E2%9C%93'
      assert_link 'April', href: 'history.cgi?q=http%3A%2F%2Fapple.com%2F&date=199704&utf8=%E2%9C%93'

      click_link 'January', href: 'history.cgi?q=http%3A%2F%2Fapple.com%2F&date=200101&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/history.cgi?q=http%3A%2F%2Fapple.com%2F&date=200101&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - January 2001 at “http://apple.com/”'
      assert_text 'January 2001 at “http://apple.com/”'
      assert_link 'January 6, 05:13:00 PM', href: '//web.archive.org/web/20010106171300if_/http://www.apple.com:80/'
      assert_text '4 KiB, Status: 200, Content-type: text/html'
    end
  end

  def test_empty_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/history.cgi?q='
      assert_current_path '/cgi-bin/history.cgi?q='

      assert_title 'Wayback Classic - Error'
      assert_text 'A query parameter must be provided'
    end
  end

  def test_no_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/history.cgi'
      assert_current_path '/cgi-bin/history.cgi'

      assert_title 'Wayback Classic - Error'
      assert_text 'A query parameter must be provided'
    end
  end

  def test_invalid_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/history.cgi?q=twitter.com&utm_medium=evil'
      assert_current_path '/cgi-bin/history.cgi?q=twitter.com&utm_medium=evil'

      assert_title 'Wayback Classic - Error'
      assert_text 'A query parameter must be provided'
    end
  end
end
