module CustomerDomains
  protected

  # Works in the same way as RestfulAuth's current_user
  def current_customer
    if subdomain = current_subdomain then
      Customer.find_by_subdomain(subdomain) rescue nil
    else
      nil
    end
  end

  # before_filter :customer_required, does not check that current_user has a log in for this customer
  def customer_required
    current_customer || access_denied
  end

  # before_filter :customer_login_required, checks for current_customer, current_user and a link between the two
  def customer_login_required
    if current_customer and current_user and CustomerUser.linked?(current_customer, current_user) then
      true
    else
      access_denied
    end
  end

end
