class UsersController < ApplicationController

  before_filter :customer_login_required, :except => [:new, :forgotten_password]
  before_filer :customer_admin_required, :only => [:index, :create]


  # This is misleadingly placed. Should probably be in the customers (or customer_signup) controller
  # it is step two of the action that started by finding the subdomain, email and invitation code in 
  # customers/new (/signup)
  def new

    if !(request.post? || (current_subdomain && params[:email] && params[:invitation_code]))
      redirect_to :subdomain => false, :controller => "customers", :action => "new"
    end
    
    # Do we have an existing user?
    @user = User.find_by_email((params[:email] || params[:user][:email] || '').downcase)
    if @user
      @new_user = false

      if request.post?
        if !@user.authenticated?(params[:user][:password])
          @user.errors.add :password, "Incorrect password"
        end
      end
    else
      @new_user = true

      @user = User.new(params[:user])
      @user.email ||= params[:email]

      # Can only happen if someone is mucking around
      if !@user.valid? && @user.errors[:email]
        flash[:error] = "Email address " + @user.errors[:email]
        redirect_to :subdomain => false, :controller => "customers", :action => "new"
        return
      end

      # Error messages only on posting the form
      @user.errors.clear if !request.post?
    end

    @customer = Customer.new(params[:customer])
    @customer.subdomain = current_subdomain

    # May happen on double-submission
    if !@customer.valid? && @customer.errors[:subdomain]
      flash[:error] = "Subdomain " + @customer.errors[:subdomain]
      redirect_to :subdomain => false, :controller => "customers", :action => "new"
      return
    end

    if !request.post?
      @customer.errors.clear
      return
    end

    # We need a token to do this for now
    @token = Token::Invitation.find_by_code params[:invitation_code]

    @token.transaction do
      if @token.valid_for?(@customer, @user)
        if ((@new_user && @user.register!) || @user.authenticated?(params[:user][:password])) && @customer.save
          CustomerUser.new(:customer => @customer, :user => @user).grant_admin!
          @token.use!
          flash[:notice] = "Done!"
          self.current_user = @user
          redirect_to :controller => "customers", :action => "dashboard"
        end
      else
        flash[:error] = "Token " + @token.errors_on_base
        redirect_to :subdomain => false, :controller => "customers", :action => "new"
    en end
    end
  end

  # List of users for the current customer
  def index
    @users = current_customer.users.scoped(:order => 'name, email')
    @user = User.new
  end

  # Invite new user to join customer
  def create
    @users = current_customer.users

    @user = User.first(:conditions => {:email => params[:user][:email].downcase})
    if @user
      if @user.customers.include? current_customer
        flash[:notice] = "#{@user.email} is already invited."
        return redirect_to(:action => :index)
      end
    else
      @user = User.new(params[:user])
      @user.state = 'passive'
    end
    @user.customers << current_customer

    if @user.save and UserMailer.deliver_invitation(current_customer, @user)
      flash[:notice] = "Great! We have sent an invitation to #{@user.email}."
      redirect_to users_path
    else
      render :action => :index
    end
  end

  # User profile
  def show
    @user = User.find(params[:id])
    raise ActiveRecord::RecordNotFound unless current_user.same_customer_as? @user
  end

  # Change password or user details
  def edit
    @user = User.find(params[:id])
    raise ActiveRecord::RecordNotFound unless current_user.can_edit_user? @user, current_customer
  end

  def update
    @user = User.find(params[:id])
    raise ActiveRecord::RecordNotFound unless current_user.can_edit_user? @user, current_customer

    # only a user themselves can change password
    if (@user == current_user) && params[:user][:password]
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    if (params[:grant_admin] || params[:revoke_admin]) && (current_user.is_admin_for?(current_customer))
      role = @user.link_to(current_customer)
      role.grant_admin! if params[:grant_admin]
      role.revoke_admin! if params[:revoke_admin]
    end

    # Other attributes
    @user.name = params[:user][:name]
    @user.email = params[:user][:email]

    if @user.save
      flash[:notice] = 'Details have been updated.'
      redirect_to @user
    else
      render :action => 'edit'
    end
  end

  # Request a password reset email
  def forgotten_password
    @email = (params[:email] || '').downcase
    @user = User.find_by_email @email
    return unless request.post?

    if @user && @user.can_reset_password?
      flash[:notice] = "We have sent you a link to reset your password. Please check your email."
      @user.password_reset_email!
      redirect_to login_path
    elsif @user
      flash[:error] = "Sorry, your account is suspended. Please contact support."
      redirect_to forgotten_password_path(:email => @email)
    else
      flash[:error] = "Sorry, we couldn't find that email address in our database."
      redirect_to forgotten_password_path(:email => @email)
    end
  end
end
