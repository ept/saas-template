module CustomerDomains
  protected

  # Works in the same way as RestfulAuth's current_user
  def current_customer
    @current_customer ||= if current_subdomain
      Customer.find_by_subdomain(current_subdomain) rescue nil
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
    if current_customer && current_user && CustomerUser.linked?(current_customer, current_user)
      true
    else
      access_denied
    end
  end

end
