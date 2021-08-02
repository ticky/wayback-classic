require 'minitest/autorun'
require 'webmock/minitest'
require_relative 'capybara_test_case'
require_relative '../cgi-bin/lib/web_client/cache'

class TestSitemap < CapybaraTestCase
  def setup
    super
    # Force the WebClient cache to always be empty
    WaybackClassic::WebClient::Cache.enabled = false
  end

  def teardown
    super
    WaybackClassic::WebClient::Cache.enabled = true
  end

  def test_sitemap
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Site map for “http://dricas.ne.jp/*”'
      assert_text 'Site map for “http://dricas.ne.jp/*”'
      assert_text '2,457 URLs have been captured'
      assert_link 'http://www.dricas.ne.jp:80/',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2F&utf8=%E2%9C%93'
      assert_text 'text/html 129 captures 116 duplicates 13 uniques'
      assert_link 'Oct 5, 1999',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2F&date=earliest&utf8=%E2%9C%93'
      assert_link 'May 5, 2002', href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2F&date=latest&utf8=%E2%9C%93'
      assert_link 'http://www.dricas.ne.jp:80/atbarai',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai&utf8=%E2%9C%93'
      assert_text 'text/html 19 captures 16 duplicates 3 uniques'
      assert_link 'Feb 19, 2001',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai&date=earliest&utf8=%E2%9C%93'
      assert_link 'Aug 20, 2007',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai&date=latest&utf8=%E2%9C%93'
      assert_link 'Next Page'
      assert_text 'Page 1 of 50'
      refute_link 'Previous Page'

      click_link 'Next Page'
      assert_current_path '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&page=2&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Site map for “http://dricas.ne.jp/*”'
      assert_text 'Site map for “http://dricas.ne.jp/*”'
      assert_text '2,457 URLs have been captured'
      assert_link 'http://www.dricas.ne.jp:80/atbarai/image/q1_silver.gif',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai%2Fimage%2Fq1_silver.gif&utf8=%E2%9C%93'
      assert_text 'image/gif 1 capture 0 duplicates 1 unique'
      assert_link 'May 10, 2003',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai%2Fimage%2Fq1_silver.gif&date=earliest&utf8=%E2%9C%93'
      assert_link 'May 10, 2003',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai%2Fimage%2Fq1_silver.gif&date=latest&utf8=%E2%9C%93'
      assert_link 'http://www.dricas.ne.jp:80/atbarai/image/screen_3.gif',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai%2Fimage%2Fscreen_3.gif&utf8=%E2%9C%93'
      assert_link 'Aug 19, 2003',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai%2Fimage%2Fscreen_3.gif&date=earliest&utf8=%E2%9C%93'
      assert_link 'Aug 19, 2003',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fatbarai%2Fimage%2Fscreen_3.gif&date=latest&utf8=%E2%9C%93'
      assert_link 'Next Page'
      assert_text 'Page 2 of 50'
      assert_link 'Previous Page'
    end
  end

  def test_sitemap_filter
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&utf8=%E2%9C%93'
      assert_current_path '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Site map for “http://dricas.ne.jp/*”'
      assert_text 'Site map for “http://dricas.ne.jp/*”'
      assert_text '2,457 URLs have been captured'

      fill_in 'Filter results', with: 'application/x'
      click_button 'Filter'

      assert_current_path '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&filter=application%2Fx&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Site map for “http://dricas.ne.jp/*”'
      assert_text 'Site map for “http://dricas.ne.jp/*”'
      assert_text '2,457 URLs have been captured'
      assert_text '2 matches'

      assert_link 'http://www.dricas.ne.jp/game/gundam/gundam_form.js',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%2Fgame%2Fgundam%2Fgundam_form.js&utf8=%E2%9C%93'
      assert_text 'application/x-javascript 1 capture 0 duplicates 1 unique'
      assert_link 'Nov 23, 2015',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%2Fgame%2Fgundam%2Fgundam_form.js&date=earliest&utf8=%E2%9C%93'
      assert_link 'Nov 23, 2015',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%2Fgame%2Fgundam%2Fgundam_form.js&date=latest&utf8=%E2%9C%93'
      assert_link 'http://www.dricas.ne.jp:80/guru2/grugru1.swf',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fguru2%2Fgrugru1.swf&utf8=%E2%9C%93'
      assert_text 'application/x-shockwave-flash 2 captures 0 duplicates 2 uniques'
      assert_link 'Jan 24, 2004',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fguru2%2Fgrugru1.swf&date=earliest&utf8=%E2%9C%93'
      assert_link 'Jul 13, 2004',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fguru2%2Fgrugru1.swf&date=latest&utf8=%E2%9C%93'
      refute_link 'Next Page'
      assert_text 'Page 1 of 1'
      refute_link 'Previous Page'

      fill_in 'Filter results', with: 'application/x-shockwave'
      click_button 'Filter'

      assert_current_path '/cgi-bin/sitemap.cgi?q=http%3A%2F%2Fdricas.ne.jp%2F*&filter=application%2Fx-shockwave&utf8=%E2%9C%93'

      assert_title 'Wayback Classic - Site map for “http://dricas.ne.jp/*”'
      assert_text 'Site map for “http://dricas.ne.jp/*”'
      assert_text '2,457 URLs have been captured'
      assert_text '1 match'

      refute_link 'http://www.dricas.ne.jp/game/gundam/gundam_form.js'
      assert_link 'http://www.dricas.ne.jp:80/guru2/grugru1.swf',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fguru2%2Fgrugru1.swf&utf8=%E2%9C%93'
      assert_text 'application/x-shockwave-flash 2 captures 0 duplicates 2 uniques'
      assert_link 'Jan 24, 2004',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fguru2%2Fgrugru1.swf&date=earliest&utf8=%E2%9C%93'
      assert_link 'Jul 13, 2004',
                  href: 'history.cgi?q=http%3A%2F%2Fwww.dricas.ne.jp%3A80%2Fguru2%2Fgrugru1.swf&date=latest&utf8=%E2%9C%93'
      refute_link 'Next Page'
      assert_text 'Page 1 of 1'
      refute_link 'Previous Page'
    end
  end

  def test_empty_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/sitemap.cgi?q=&page='
      assert_current_path '/cgi-bin/sitemap.cgi?q=&page='

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end

  def test_no_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/sitemap.cgi'
      assert_current_path '/cgi-bin/sitemap.cgi'

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end

  def test_invalid_parameters
    VCR.use_cassette "#{self.class.name}\##{__callee__}" do
      visit '/cgi-bin/sitemap.cgi?q=twitter.com&utm_medium=evil'
      assert_current_path '/cgi-bin/sitemap.cgi?q=twitter.com&utm_medium=evil'

      assert_title 'Wayback Classic - Error'
      assert_text 'A `q` parameter must be supplied, and no other parameters are accepted'
    end
  end
end
