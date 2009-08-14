require File.dirname(__FILE__) + '/../spec_helper'

describe MailingObserver do

  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  describe 'for users' do
    fixtures :users

    before :each do
      # Create a new customer with one user
      @user = User.new :email => 'asdf@asdf.com', :name => 'asdf'
      @user.password = 'foobar'
      @user.password_confirmation = 'foobar'
      @user.register!
      @customer = Customer.new :subdomain => 'foo'
      @customer.save!
      @link = CustomerUser.new(:customer => @customer, :user => @user)
      @link.activate!
      @link.grant_admin!
    end

    it 'should send an activation email when a new user signs up' do
      ActionMailer::Base.deliveries.size.should == 1
      mail = ActionMailer::Base.deliveries[0]
      mail.to.should include('asdf@asdf.com')
      mail.body.should =~ /verify your email address/
      extract_token_code = /https?:\/\/#{Rails::configuration.domain_name}\/(\w+)/
      mail.body.should =~ extract_token_code

      mail.body =~ extract_token_code
      token = Token::EmailValidation.find_by_code $1
      token.should_not be_nil
      token.should be_a_valid_token
      token.param.should_not be_nil
      token.param[:user_id].should == @user.id
    end

    it 'should send an invitation email when a new user is invited to join a customer' do
      ActionMailer::Base.deliveries = []
      @new_user = User.new :email => 'fdsa@fdsa.com'
      @new_user.state = 'passive'
      @new_user.customers << @customer
      @new_user.save!

      ActionMailer::Base.deliveries.size.should == 1
      mail = ActionMailer::Base.deliveries[0]
      mail.to.should include('fdsa@fdsa.com')
      mail.body.should =~ /You have been invited/
      extract_token_code = /https?:\/\/#{@customer.subdomain}.#{Rails::configuration.domain_name}\/(\w+)/
      mail.body.should =~ extract_token_code

      mail.body =~ extract_token_code
      token = Token::Invitation.find_by_code $1
      token.should_not be_nil
      token.should be_a_valid_token
      token.param.should_not be_nil
      token.param[:subdomain].should == @customer.subdomain
      token.param[:email].should == @new_user.email
    end

    it 'should send an invitation email when an existing user is invited to join a customer' do
      ActionMailer::Base.deliveries = []
      @quentin = User.find_by_email('quentin@example.com')
      @quentin.customers << @customer
      @quentin.save!

      ActionMailer::Base.deliveries.size.should == 1
      mail = ActionMailer::Base.deliveries[0]
      mail.to.should include('quentin@example.com')
      mail.body.should =~ /You have been invited/
      extract_token_code = /https?:\/\/#{@customer.subdomain}.#{Rails::configuration.domain_name}\/(\w+)/
      mail.body.should =~ extract_token_code

      mail.body =~ extract_token_code
      token = Token::Invitation.find_by_code $1
      token.should_not be_nil
      token.should be_a_valid_token
      token.param.should_not be_nil
      token.param[:subdomain].should == @customer.subdomain
      token.param[:email].should == @quentin.email
    end
  end

end
