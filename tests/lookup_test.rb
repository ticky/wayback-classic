require 'minitest/autorun'
require 'vcr'
require 'webmock/minitest'
require_relative 'capybara_test_case'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:host, :method, :path]
  }
end

class TestLookup < CapybaraTestCase
  def test_keywords_redirect
    VCR.use_cassette 'test_keywords_redirect' do
      visit "/cgi-bin/lookup.cgi?q=apple&utf8=%E2%9C%93"
      assert_current_path "/cgi-bin/search.cgi?q=apple&utf8=%E2%9C%93"
    end
  end

  def test_utf8_canary_dreampassport3_redirect
    VCR.use_cassette 'test_utf8_canary_dreampassport3_redirect' do
      visit "/cgi-bin/lookup.cgi?q=dricas&utf8=%EF%BF%BD%13"
      assert_current_path "/cgi-bin/search.cgi?q=dricas&utf8=%EF%BF%BD%13"
    end
  end

  def test_utf8_canary_safari_jis_redirect
    VCR.use_cassette 'test_utf8_canary_safari_jis_redirect' do
      visit "/cgi-bin/lookup.cgi?q=apple&utf8=%EF%BF%BD%26%2365533%3B"
      assert_current_path "/cgi-bin/search.cgi?q=apple&utf8=%EF%BF%BD%26%2365533%3B"
    end
  end

  def test_empty_parameters
    VCR.use_cassette 'test_empty_parameters' do
      visit "/cgi-bin/lookup.cgi?q="
      assert_current_path "/cgi-bin/lookup.cgi?q="

      assert_title "Wayback Classic - Error"
      assert_text "A `q` parameter must be supplied, and no other parameters are accepted"
    end
  end

  def test_no_parameters
    VCR.use_cassette 'test_no_parameters' do
      visit "/cgi-bin/lookup.cgi"
      assert_current_path "/cgi-bin/lookup.cgi"

      assert_title "Wayback Classic - Error"
      assert_text "A `q` parameter must be supplied, and no other parameters are accepted"
    end
  end

  def test_invalid_parameters
    VCR.use_cassette 'test_invalid_parameters' do
      visit "/cgi-bin/lookup.cgi?q=twitter&utm_medium=evil"
      assert_current_path "/cgi-bin/lookup.cgi?q=twitter&utm_medium=evil"

      assert_title "Wayback Classic - Error"
      assert_text "A `q` parameter must be supplied, and no other parameters are accepted"
    end
  end
end
