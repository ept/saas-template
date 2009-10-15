module SecureDomain
  protected
  # Returns 'http' or 'https' depending on the setting in the environment
  def login_url_protocol
    Rails::configuration.https_login ? 'https' : 'http'
  end

  # When using a wildcard SSL certificate for *.example.com then requests to example.com
  # cannot be authenticated. Therefore any SSL URLs which wouldn't otherwise have a
  # subdomain should be directed to a special subdomain, e.g. secure.example.com.
  def login_url_subdomain
    Rails::configuration.https_login ? 'secure' : false
  end

  # If we have an SSL certificate then use either the given subdomain or the "secure" one
  # and set protocol to https, in development we are unlikely to have the https, so just
  # use http (in which case no special subdomain is needed)
  def secure_subdomain(params={})
    params[:subdomain] ||= login_url_subdomain
    params[:protocol] = login_url_protocol
    params
  end

  # Go back to the root of the site, no https, no subdomains, just plain-old http://go-test.it/
  def no_subdomain(params={})
    params[:subdomain] = false
    params[:protocol] = 'http'
    params
  end


end
