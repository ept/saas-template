require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  describe "when creating a new user" do

#    before :each do
#      @params = {'subdomain' => "ept", 'email' => "hasni@eptcomputing.com", 'invitation_code' => "ab48f"}
#    end
#
#    it "should redirect back to /signup with bad parameters" do
#      @params.delete['email']
#      get @params
#      response.should redirect_to "http://test.host/signup"
#    end

    it "has probably been tested enough by features"
  end
  
  describe "when inviting a new user to join a customer" do
    before :each do
      @widget = mock_model Customer, {:subdomain => "widget"}
      @current_user = mock_model User, {:email => 'current.user@example.com', :customers => [@widget]}
      @existing_user = mock_model User, {:email => 'existing.user@example.com', :customers => []}
      @existing_user.should_receive(:save).any_number_of_times.and_return(true)
      @new_user = mock_model User, {:email => 'new.user@example.com', :customers => []}
      @new_user.should_receive(:save).any_number_of_times.and_return(true)
      @widget.should_receive(:users).any_number_of_times.and_return([@current_user])
      controller.should_receive(:customer_login_required).any_number_of_times.and_return(true)
      controller.should_receive(:customer_admin_required).any_number_of_times.and_return(true)
      controller.should_receive(:current_customer).any_number_of_times.and_return(@widget)
      controller.should_receive(:current_user).any_number_of_times.and_return(@current_user)
    end

    it "should detect an existing account with another customer" do
      User.should_receive(:find).with(:first, :conditions => {:email => 'existing.user@example.com'}).and_return(@existing_user)
      post :create, :user => {:email => 'EXISTING.USER@example.com'}
      response.should redirect_to("/users")
      flash[:notice].should =~ /We have sent an invitation/
      @existing_user.customers.should include(@widget)
    end

    it "should create a new passive account for an unknown address" do
      User.should_receive(:find).with(:first, :conditions => {:email => 'new.user@example.com'}).and_return(nil)
      User.should_receive(:new).with({'email' => 'new.user@example.com'}).and_return(@new_user)
      @new_user.should_receive(:state=).with('passive')
      post :create, :user => {:email => 'new.user@example.com'}
      response.should redirect_to("/users")
      flash[:notice].should =~ /We have sent an invitation/
      @new_user.customers.should include(@widget)
    end
  end


  describe "#update" do
    before :each do
      @widget = mock_model Customer, {:subdomain => "widget"}

      @admin_role = mock_model CustomerUser
      @admin = mock_model User, {:state => 'active'}
      @admin.should_receive(:link_to).any_number_of_times.and_return(@admin_role)
      @admin.should_receive(:is_admin_for?).any_number_of_times.and_return(true)
      @admin.should_receive(:can_edit_user?).any_number_of_times.and_return(true)

      @user_role = mock_model CustomerUser
      @user = mock_model User
      @user.should_receive(:link_to).any_number_of_times.and_return(@user_role)
      @user.should_receive(:is_admin_for?).any_number_of_times.and_return(false)
      @user.should_receive(:can_edit_user?).with(@user, @widget).any_number_of_times.and_return(true)
      @user.should_receive(:can_edit_user?).with(@admin, @widget).any_number_of_times.and_return(false)

      controller.should_receive(:customer_login_required).any_number_of_times.and_return(true)
      controller.should_receive(:current_customer).any_number_of_times.and_return(@widget)
    end

    it "should allow a user to change their own details and password" do
      controller.should_receive(:current_user).any_number_of_times.and_return(@user)
      User.should_receive(:find).and_return(@user)
      @user.should_receive(:name=).with('john smith')
      @user.should_receive(:email=).with('blah@blah.com')
      @user.should_receive(:password=).with('blahblah')
      @user.should_receive(:password_confirmation=).with('blahblah')
      @user.should_receive(:save).and_return(true)
      post :update, :user => {:name => 'john smith', :email => 'blah@blah.com',
        :password => 'blahblah', :password_confirmation => 'blahblah'}
      response.should be_redirect
      flash[:notice].should =~ /have been updated/
    end
    
    it "should not allow an admin to change another user's password" do
      controller.should_receive(:current_user).any_number_of_times.and_return(@admin)
      User.should_receive(:find).and_return(@user)
      @user.should_receive(:name=).with('john smith')
      @user.should_receive(:email=).with('blah@blah.com')
      @user.should_not_receive(:password=)
      @user.should_receive(:save).and_return(true)
      post :update, :user => {:name => 'john smith', :email => 'blah@blah.com',
        :password => 'blahblah', :password_confirmation => 'blahblah'}
      response.should be_redirect
      flash[:notice].should =~ /have been updated/
    end
    
    it "should allow an admin to grant admin permissions" do
      controller.should_receive(:current_user).any_number_of_times.and_return(@admin)
      User.should_receive(:find).and_return(@user)
      @user.should_receive(:name=).with('john smith')
      @user.should_receive(:email=).with('blah@blah.com')
      @user.should_receive(:save).and_return(true)
      @user_role.should_receive(:grant_admin!)
      post :update, :user => {:name => 'john smith', :email => 'blah@blah.com'}, :grant_admin => '1'
      response.should be_redirect
      flash[:notice].should =~ /have been updated/
    end
    
    it "should allow an admin to revoke admin permissions" do
      controller.should_receive(:current_user).any_number_of_times.and_return(@admin)
      User.should_receive(:find).and_return(@user)
      @user.should_receive(:name=).with('john smith')
      @user.should_receive(:email=).with('blah@blah.com')
      @user.should_receive(:save).and_return(true)
      @user_role.should_receive(:revoke_admin!)
      post :update, :user => {:name => 'john smith', :email => 'blah@blah.com'}, :revoke_admin => '1'
      response.should be_redirect
      flash[:notice].should =~ /have been updated/
    end
    
    it "should not allow a normal user to grant admin permissions" do
      controller.should_receive(:current_user).any_number_of_times.and_return(@user)
      User.should_receive(:find).and_return(@admin)
      lambda {
        post :update, :user => {:name => 'john smith', :email => 'blah@blah.com'}, :revoke_admin => '1'
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end


  describe "#forgotten_password" do
    before :each do
      @active_user = mock_model User, {:state => 'active'}
      @active_user.should_receive(:can_reset_password?).any_number_of_times.and_return(true)
      @suspended_user = mock_model User, {:state => 'suspended'}
      @suspended_user.should_receive(:can_reset_password?).any_number_of_times.and_return(false)
    end

    it "should not require login" do
      get :forgotten_password
      response.should render_template("users/forgotten_password.html.erb")
    end
    
    it "should send a password email if the account is valid" do
      User.should_receive(:find_by_email).with('blah@blah.com').and_return(@active_user)
      @active_user.should_receive(:password_reset_email!)
      post :forgotten_password, :email => 'BLAH@BLAH.com'
      response.should redirect_to("/login")
      flash[:notice].should =~ /We have sent you a link/
    end

    it "should not send a password email if the account is suspended" do
      User.should_receive(:find_by_email).with('blah@blah.com').and_return(@suspended_user)
      post :forgotten_password, :email => 'BLAH@BLAH.com'
      response.should redirect_to("/forgotten_password?email=blah%40blah.com")
      flash[:error].should =~ /your account is suspended/
    end

    it "should display an error if the account is unknown" do
      User.should_receive(:find_by_email).with('blah@blah.com').and_return(nil)
      post :forgotten_password, :email => 'BLAH@BLAH.com'
      response.should redirect_to("/forgotten_password?email=blah%40blah.com")
      flash[:error].should =~ /we couldn't find/
    end
  end

end
