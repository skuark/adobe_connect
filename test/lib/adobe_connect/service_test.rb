require File.expand_path('../../test_helper.rb', File.dirname(__FILE__))

class AdobeConnectServiceTest < MiniTest::Unit::TestCase
  LOGIN_SUCCESS = File.read('test/fixtures/log_in_success.xml')
  LOGIN_FAIL    = File.read('test/fixtures/log_in_fail.xml')

  def setup
    @service = AdobeConnect::Service.new(username: 'name', password: 'password',
      domain: 'http://example.com')
  end

  def test_initialize_takes_a_config_hash
    assert_equal @service.username, 'name'
    assert_equal @service.domain,   URI.parse('http://example.com')
  end

  def test_password_is_not_be_public
    assert_raises(NoMethodError) { @service.password }
  end

  def test_authenticated_defaults_to_false
    assert_equal @service.authenticated?, false
  end

  def test_log_in_authenticates
    response = mock(status: 200)
    response.expects(:fetch).returns('BREEZESESSION=12345')
    response.expects(:body).returns(LOGIN_SUCCESS)
    ac_response = AdobeConnect::Response.new(response)
    @service.client.stubs(:get).returns(ac_response)

    @service.log_in
    assert @service.authenticated?
  end

  def test_log_in_creates_a_session
    response = mock(status: 200)
    response.expects(:fetch).with('set-cookie').returns('BREEZESESSION=12345;HttpOnly;path=/')
    response.expects(:body).returns(LOGIN_SUCCESS)
    ac_response = AdobeConnect::Response.new(response)
    @service.client.stubs(:get).
      with("/api/xml?action=login&login=name&password=password").
      returns(ac_response)

    @service.log_in
    assert_equal @service.session, '12345'
  end

  def test_log_in_returns_false_on_failure
    response = mock(status: 200)
    response.expects(:body).returns(LOGIN_FAIL)
    ac_response = AdobeConnect::Response.new(response)
    @service.client.stubs(:get).returns(ac_response)

    refute @service.log_in
  end

  def test_unknown_methods_are_proxied_to_the_connect_service
    @service.expects(:request).with('method-name', a: 1)
    @service.method_name(a: 1)
  end
end