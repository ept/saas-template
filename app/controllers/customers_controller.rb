class CustomersController < ApplicationController

  before_filter :customer_login_required, :except => [:new, :choose]
  before_filter :login_required, :only => :choose

  def new
    get_params = {}
    ['invitation_code', 'subdomain'].each{|param| get_params[param] = params[param] if params[param] }
    get_params = nil if get_params == {}

    @customer_signup = CustomerSignup.from_params_and_session(params[:customer_signup] || get_params, session)

    return unless request.post?

    if @customer_signup.has_invitation == 1 && @customer_signup.valid?
      redirect_to :subdomain => @customer_signup.subdomain, :controller => :users, :action => :new, :invitation_code => @customer_signup.invitation_code
    end
  end

  def dashboard

  end

  def index
    render :action => :dashboard
  end

  # TODO: add some welcome information? or just merge this method with something else.
  def welcome
    render :action => :dashboard
  end
  
  # Presented to users when they log in, skips the dialogue if there's no choice
  def choose
    @customers = current_user.customers
    if current_customer && CustomerUser.linked?(current_customer, current_user)
      redirect_back_or_default root_url(:subdomain => current_customer.subdomain), :subdomain => current_customer.subdomain
    elsif !@customers || @customers.count == 0
      logger.warn("Ouch! #{current_user.email} has no customers")
      redirect_back_or_default(secure_subdomain(:action => "new"), secure_subdomain)
    elsif @customers.count == 1
      if !CustomerUser.linked?(@customers[0], current_user)
        logout_keeping_session!
        access_denied
      else
        redirect_back_or_default root_url(:subdomain => @customers[0].subdomain), :subdomain => @customers[0].subdomain
      end
    else
      # Render choice page
    end
  end

end
