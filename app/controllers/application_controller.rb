# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include CustomerDomains
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  before_filter :set_global_hostnames

  def set_global_hostnames
    # Allow sessions to persist across subdomains
    ActionController::Base.session_options[:domain] = SubdomainFu.host_without_subdomain(request.env['SERVER_NAME'])

    # Why doesn't rails do this itself...
    ActionMailer::Base.default_url_options[:host] = request.env['SERVER_NAME']
    ActionMailer::Base.default_url_options[:port] = request.env['SERVER_PORT']
  end

end
