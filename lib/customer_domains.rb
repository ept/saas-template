module CustomerDomains
  protected

  # Inclusion hook to make #current_customer available as ActionView helper method.
  def self.included(base)
    base.send :helper_method, :current_customer if base.respond_to? :helper_method
  end

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

  def logged_in_as_current_customer?
    current_customer && current_user && CustomerUser.linked?(current_customer, current_user)
  end

  # before_filter :customer_login_required, checks for current_customer, current_user and a link between the two
  def customer_login_required
    logged_in_as_current_customer? || access_denied
  end

  # before_filter :customer_admin_required, checks for current_customer, current_user, and a link with an "admin" flag between the two
  def customer_admin_required
    if current_customer && current_user && current_user.is_admin_for?(current_customer)
      true
    else
      flash[:error] = "You need to log in as an administrator to do that"
      access_denied
    end
  end

end
