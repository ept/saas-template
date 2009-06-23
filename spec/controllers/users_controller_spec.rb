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
