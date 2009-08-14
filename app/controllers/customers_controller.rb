class CustomersController < ApplicationController

  before_filter :customer_login_required, :except => [:new, :choose]
  before_filter :login_required, :only => :choose

  def new
    get_params = {}
    ['invitation_code', 'subdomain'].each{|param| get_params[param] = params[param] if params[param] }
    get_params = nil if get_params == {}

    @customer_signup = CustomerSignup.new(params[:customer_signup] || get_params)

    if Token::BetaInvitation.find_by_code(session[:token_code]).valid_token?
      @customer_signup.invitation_code ||= session[:token_code]
    end
    return unless request.post?

    if @customer_signup.valid? then
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
    if current_customer and CustomerUser.linked?(current_customer, current_user) then
      redirect_back_or_default root_url(:subdomain => current_customer.subdomain), :subdomain => current_customer.subdomain
    elsif !@customers or @customers.count == 0 then
      redirect_back_or_default({:action => "new", :subdomain => false}, {:subdomain => false})
    elsif @customers.count == 1 then
      redirect_back_or_default root_url(:subdomain => @customers[0].subdomain), :subdomain => @customers[0].subdomain
    else
      #Render choice page
    end
  end

end
