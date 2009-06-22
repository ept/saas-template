class CustomersController < ApplicationController

  before_filter :customer_login_required, :except => :new
  def new
    @customer_signup = CustomerSignup.new(params[:customer_signup])
    return unless request.post?

    if @customer_signup.valid? then
      redirect_to :subdomain => @customer_signup.subdomain, :controller => :users, :action => :new, :invitation_code => @customer_signup.invitation_code, :email => @customer_signup.email
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
    if current_customer and CustomerUser.linked?(current_customer, current_user) then
      redirect_to :action => "dashboard", :subdomain => current_customer.subdomain
    elsif !@customers or @customers.count == 0 then
      redirect_to :action => "new", :subdomain => false
    elsif @customers.count == 1 then
      redirect_to :action => "dashboard", :subdomain => @customers[0].subdomain
    end
  end

end
