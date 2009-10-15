# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include AuthenticatedSystem
  include CustomerDomains
  include SecureDomain

  helper :all # include all helpers, all the time
  helper_method :current_customer, :login_url_protocol, :login_url_subdomain, :secure_subdomain, :no_subdomain
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  before_filter :set_timezone
  before_filter :log_user

  protected

  def set_timezone
    Time.zone = current_user.time_zone if current_user
  end

  def log_user
    if logged_in?
      logger.info "Logged in as user ##{current_user.id} (#{current_user.email})"
    else
      logger.info "Not logged in"
    end
  end

  # Override ActionController's default exception handling to deal with +InvalidAuthenticityToken+ errors
  # nicely. Most often, +InvalidAuthenticityToken+ happen as follows: the user has two browser tabs open,
  # one with a form page loaded. In the other tab, they log out and log back in again (thus destroying
  # their session and creating a new one). Back in the first tab, they try to submit the form, but that
  # page's authenticity token is no longer valid. Instead of giving them a horrible error message,
  # we should log them out and ask them to log in again.
  def rescue_action(exception)
    return super unless exception.kind_of? ActionController::InvalidAuthenticityToken
    logger.info "Handling #{exception} by forcing fresh login"

    # Forget about any renders or redirects previously called
    erase_results if performed?

    # Nuke their session
    logout_killing_session!
    kill_remember_cookie!

    # Try to take them back where they came from when they log in again
    flash[:error] = "Please log in."
    redirect = {:return_to => (request.env["HTTP_REFERER"] || '').gsub(/.*:\/\/[^\/]*/, '')}
		redirect[:protocol] = 'https' if Rails::configuration.https_login
    redirect_to(login_url(redirect))
  end
end
