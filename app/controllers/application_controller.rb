# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include AuthenticatedSystem
  include CustomerDomains
  helper :all # include all helpers, all the time
  helper_method :current_customer
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :set_timezone

  protected

  def set_timezone
    Time.zone = current_user.time_zone if current_user
  end
end
