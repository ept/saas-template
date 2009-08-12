require File.dirname(__FILE__) + '/../../spec_helper'
describe Token::Invitation do

  before :each do
    @customer = Customer.new :subdomain => 'foo'
    @user = User.new :email => 'hello@example.com'
    @unrestricted_token = Token::Invitation.new :code => 'test'
    @customer_token = Token::Invitation.new :code => 'customer', :param => {:subdomain => 'foo'}
    @user_token = Token::Invitation.new :code => 'user', :param => {:email => 'hello@example.com'}
    @customer_user_token = Token::Invitation.new :code => 'customer_user', :param => {:subdomain => 'foo', :email => 'hello@example.com'}
  end
  
  it "should be valid for anything if unrestricted" do
    @unrestricted_token.valid_for?(Customer.new, User.new).should be_true
  end

  it "should be limited to a customer if needed" do
    @customer_token.valid_for?(@customer, User.new).should be_true
    @customer_token.valid_for?(Customer.new, User.new).should be_false
  end

  it "should be limited to a user if needed" do
    @user_token.valid_for?(Customer.new, @user).should be_true
    @user_token.valid_for?(Customer.new, User.new).should be_false
  end

  it "should be limited to a customer and user if needed" do
    @customer_user_token.valid_for?(@customer, @user).should be_true
    @customer_user_token.valid_for?(Customer.new, @user).should be_false
    @customer_user_token.valid_for?(@customer, User.new).should be_false
    @customer_user_token.valid_for?(Customer.new, User.new).should be_false
  end

  it "should allow using after a valid_for? check" do
    @unrestricted_token.transaction do
      @unrestricted_token.valid_for?(Customer.new, User.new)
      @unrestricted_token.use!
    end
  end

end
