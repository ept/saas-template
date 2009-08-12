class UsersController < ApplicationController

  before_filter :customer_login_required, :except => [:new, :forgotten_password, :accept_invitation, :validate_email, :password_reset]
  before_filter :customer_admin_required, :only => [:index, :create]


  # This is misleadingly placed. Should probably be in the customers (or customer_signup) controller
  # it is step two of the action that started by finding the subdomain, email and invitation code in 
  # customers/new (/signup)
  def new
    if !(request.post? || (current_subdomain && params[:invitation_code]))
      redirect_to :subdomain => false, :controller => "customers", :action => "new"
    end
    
    # Do we have an existing user?
    @user = User.find_by_email((params[:email] || (params[:user] && params[:user][:email]) || '').downcase)
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
      if params[:user]
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
      end
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
      @user.errors.clear
      return
    end

    # We need a token to do this for now
    @token = Token::BetaInvitation.find_by_code params[:invitation_code]

    @token.transaction do
      if @token.valid_token?
        if ((@new_user && @user.register!) || @user.authenticated?(params[:user][:password])) && @customer.save
          link = CustomerUser.new(:customer => @customer, :user => @user)
          link.activate!
          link.grant_admin!

          @token.use!

          logout_keeping_session! if current_user
          self.current_user = @user 

          flash[:notice] = "Done!"
          redirect_to :controller => "customers", :action => "welcome"
        end
      else
        flash[:error] = "Token " + @token.errors_on_base
        redirect_to :subdomain => false, :controller => "customers", :action => "new"
      end
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

    if @user.save
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
    @user.attributes = params[:user]

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

  # Accept an invitation to join a customer
  def accept_invitation

    @token = Token::Invitation.find_by_code params[:id]

    @customer = Customer.find_by_subdomain @token.param[:subdomain]
    @user = User.find_by_email @token.param[:email]

    if current_user && @user != current_user
      logout_keeping_session!
    end

    @new_user = @user.state == 'passive'
    if request.post?
      @token.transaction do
        if @token.valid_for?(@customer, @user) 
          if @new_user
            # For some reason rails won't give this error
            @user.errors.add(:password, "can't be blank") if params[:user][:password] == ""
            @user.password = params[:user][:password]
            @user.password_confirmation = params[:user][:password_confirmation]
          end

          if ((@new_user && @user.register!) || @user.authenticated?(params[:user][:password]))
            @token.use!
            @user.activate! if @user.state == 'pending'
            CustomerUser.find(:first, :conditions => {:user_id => @user.id, :customer_id => @customer.id}).activate!

            self.current_user = @user
            flash[:notice] = "Done!"
            return redirect_to(:controller => "customers", :action => "welcome")
          end
        else
          flash[:error] = "Token " + @token.errors[:base]
          return redirect_to(:action => :accept_invitation)
        end
      end

      if !@new_user && !@user.authenticated?(params[:user][:password])
        @user.errors.add :password, "Incorrect password"
      end
    end

    @existing_customer = true
    render :action => :new
  end

  def validate_email
    token = Token::EmailValidation.find_by_code params[:id]
    user = User.find_by_id(token.param[:user_id])

    token.transaction do

      if token.valid_token? && user
        user.activate!
        token.use!
        self.current_user = user
        flash[:notice] = "Email confirmed"
        redirect_to :controller => :customers, :action => :choose

      else 
        if user && user.state == 'active'
          self.current_user = user
          flash[:notice] = "Email previously confirmed"
          redirect_to :controller => :customers, :action => :choose
        else
          flash[:error] = "Token " + token.errors[:base]
          redirect_to :controller => :about
        end
      end
    end
  end

  def password_reset
    token = Token::PasswordReset.find_by_code params[:id]
    @user = token.user

    token.transaction do

      if token.valid_token?
        if @user && @user.can_reset_password?
        
          if request.post?
            @user.password = params[:user][:password]
            @user.password_confirmation = params[:user][:password_confirmation]
            if params[:user][:password] == ""
              @user.errors.add :password, "can't be blank"
            elsif @user.save
              token.use!
              self.current_user = @user
              return redirect_to(:controller => :customers, :action => :choose)
            end
          end
        else
          flash[:error] = "You may not reset your password, please contact support."
        end
      else
        flash[:error] = "Token " + token.errors[:base]
      end
    end
  end
end
