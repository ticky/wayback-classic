require 'minitest/autorun'
require 'vcr'
require 'webmock/minitest'
require_relative 'capybara_test_case'
require_relative '../cgi-bin/lib/web_client'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  # c.debug_logger = $stderr
  c.default_cassette_options = {
    record: :once,
    match_requests_on: %i[host method path],
    allow_unused_http_interactions: false
  }
end

class TestSearch < CapybaraTestCase
  def setup
    super
    # Force the WebClient cache to always be empty
    WaybackClassic::WebClient::Cache.enabled = false
  end

  def teardown
    super
    WaybackClassic::WebClient::Cache.enabled = true
  end

  def test_keywords_search
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/search.cgi?q=apple&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/search.cgi?q=apple&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Searching for “apple”'
      assert_text 'Search results for “apple”'
      assert_link 'tuaw.com', href: 'history.cgi?q=http%3A%2F%2Ftuaw.com%2F&utf8=%E2%9C%93'
      assert_link 'Earliest', href: 'history.cgi?q=http%3A%2F%2Ftuaw.com%2F&date=earliest&utf8=%E2%9C%93'
      assert_link 'Latest', href: 'history.cgi?q=http%3A%2F%2Ftuaw.com%2F&date=latest&utf8=%E2%9C%93'
      assert_text 'tuaw 1,048,451 captures between 2004 and 2015'
      assert_link 'apple.stackexchange.com', href: 'history.cgi?q=http%3A%2F%2Fapple.stackexchange.com%2F&utf8=%E2%9C%93'
      assert_link 'Earliest', href: 'history.cgi?q=http%3A%2F%2Fapple.stackexchange.com%2F&date=earliest&utf8=%E2%9C%93'
      assert_link 'Latest', href: 'history.cgi?q=http%3A%2F%2Fapple.stackexchange.com%2F&date=latest&utf8=%E2%9C%93'
      assert_text 'ask different (apple) 2,013,764 captures between 2010 and 2016'
      assert_link 'appleforums.net', href: 'history.cgi?q=http%3A%2F%2Fappleforums.net%2F&utf8=%E2%9C%93'
      assert_link 'Earliest', href: 'history.cgi?q=http%3A%2F%2Fappleforums.net%2F&date=earliest&utf8=%E2%9C%93'
      assert_link 'Latest', href: 'history.cgi?q=http%3A%2F%2Fappleforums.net%2F&date=latest&utf8=%E2%9C%93'
      assert_text 'apple forum 35,690 captures between 2004 and 2016'
    end
  end

  def test_keywords_search_utf8_canary_dreampassport3
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/search.cgi?q=site:ne.jp%20dricas&utf8=%EF%BF%BD%13'
      assert_current_path '/cgi-bin/search.cgi?q=site:ne.jp%20dricas&utf8=%EF%BF%BD%13'

      assert_title 'Wayback Classic - Searching for "site:ne.jp dricas"'
      # Due to the Shift JIS hack, this can't use Capybara's normal matchers here
      assert_includes page.body, CGI.escapeHTML('Search results for "site:ne.jp dricas"')
      assert_includes page.body, CGI.escapeHTML('pso.dricas.ne.jp')
      assert_includes page.body, CGI.escapeHTML('aerodancing.dricas.ne.jp')
      assert_includes page.body, CGI.escapeHTML('mtsuku.dricas.ne.jp')
      assert_includes page.body, CGI.escapeHTML('eldorado.dricas.ne.jp')
      assert_includes page.body, CGI.escapeHTML('dabitsuku.dricas.ne.jp')
      assert_includes page.body, CGI.escapeHTML('公式ｈｐ'.encode('Shift_JIS').force_encoding('ASCII-8BIT'))
      assert_includes page.body, CGI.escapeHTML('shiyouyo.dricas.ne.jp')
      assert_includes page.body, CGI.escapeHTML('ゴルフしようよ'.encode('Shift_JIS').force_encoding('ASCII-8BIT'))
    end
  end

  def test_empty_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/search.cgi?q='
      assert_current_path '/cgi-bin/search.cgi?q='

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end

  def test_no_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/search.cgi'
      assert_current_path '/cgi-bin/search.cgi'

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end

  def test_invalid_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/search.cgi?q=twitter&utm_medium=evil'
      assert_current_path '/cgi-bin/search.cgi?q=twitter&utm_medium=evil'

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end
end
