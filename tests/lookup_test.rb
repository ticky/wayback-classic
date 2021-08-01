require 'minitest/autorun'
require 'webmock/minitest'
require_relative 'capybara_test_case'
require_relative '../cgi-bin/lib/web_client'

class TestLookup < CapybaraTestCase
  def setup
    super
    # Force the WebClient cache to always be empty
    WaybackClassic::WebClient::Cache.enabled = false
  end

  def teardown
    super
    WaybackClassic::WebClient::Cache.enabled = true
  end

  def test_keywords_redirect
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q=apple&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/search.cgi?q=apple&utf8=%E2%9C%93'
    end
  end

  def test_url_redirect
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q=apple.com&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/history.cgi?q=apple.com&utf8=%E2%9C%93'
    end
  end

  def test_url_wildcard_redirect
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q=dricas.ne.jp%2F*&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/sitemap.cgi?q=dricas.ne.jp%2F*&utf8=%E2%9C%93'
    end
  end

  def test_utf8_canary_dreampassport3_redirect
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q=dricas&utf8=%EF%BF%BD%13'
      assert_current_path '/cgi-bin/search.cgi?q=dricas&utf8=%EF%BF%BD%13'
    end
  end

  def test_utf8_canary_safari_jis_redirect
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q=apple&utf8=%EF%BF%BD%26%2365533%3B'
      assert_current_path '/cgi-bin/search.cgi?q=apple&utf8=%EF%BF%BD%26%2365533%3B'
    end
  end

  def test_empty_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q='
      assert_current_path '/cgi-bin/lookup.cgi?q='

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end

  def test_no_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi'
      assert_current_path '/cgi-bin/lookup.cgi'

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end

  def test_invalid_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/lookup.cgi?q=twitter&utm_medium=evil'
      assert_current_path '/cgi-bin/lookup.cgi?q=twitter&utm_medium=evil'

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end
end
