class UsersController < ApplicationController

  # This is misleadingly placed. Should probably be in the customers (or customer_signup) controller
  # it is step two of the action that started by finding the subdomain, email and invitation code in 
  # customers/new (/signup)
  def new

    if not (request.post? or (current_subdomain and params[:email] and params[:invitation_code])) then
      redirect_to :subdomain => false, :controller => "customers", :action => "new"
    end
    
    # Do we have an existing user?
    @user = User.find_by_email(params[:email] || params[:user][:email])
    if @user then
      @new_user = false

      if request.post? then
        if not @user.authenticated? params[:user][:password] then
          @user.errors.add :password, "Incorrect password"
        end
      end
    else
      @new_user = true

      @user = User.new(params[:user])
      @user.email ||= params[:email]

      # Can only happen if someone is mucking around
      if not @user.valid? and @user.errors[:email] then
        flash[:error] = "Email address " + @user.errors[:email]
        redirect_to :subdomain => false, :controller => "customers", :action => "new"
        return
      end

      # Set some defaults
      if not request.post? then
        @user.errors.clear
        @user.email = params[:email]
        @user.name = @user.email[/^[^@]+/].split(/[\._\-\s]/).each{|w| w.capitalize! }.join(' ')
      end
    end

    @customer = Customer.new(params[:customer])
    @customer.subdomain = current_subdomain

    # May happen on double-submission
    if not @customer.valid? and @customer.errors[:subdomain] then
      flash[:error] = "Subdomain " + @customer.errors[:subdomain]
      redirect_to :subdomain => false, :controller => "customers", :action => "new"
      return
    end

    if not request.post? then
      @customer.errors.clear
      return
    end

    # We need a token to do this for now
    @token = Token::Invitation.find_by_code params[:invitation_code]

    @token.transaction do
      if @token.valid_for?(@customer, @user) then
        if ((@new_user and @user.save) or @user.authenticated?(params[:user][:password])) and @customer.save then
          CustomerUser.new(:customer => @customer, :user => @user).save!
          @token.use!
          flash[:notice] = "Done!"
          self.current_user = @user
          redirect_to :controller => "customers", :action => "dashboard"
        end
      else
        flash[:error] = "Token" + @token.errors_on_base
        redirect_to :subdomain => false, :controller => "customers", :action => "new"
      end
    end
  end

end
