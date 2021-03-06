# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

# Be sure to include AuthenticatedTestHelper in spec/spec_helper.rb instead.
# Then, you can remove it from this and the functional test.
include AuthenticatedTestHelper

describe User do
  fixtures :users

  describe 'being created' do
    before do
      @user = nil
      @creating_user = lambda do
        @user = create_user
        violated "#{@user.errors.full_messages.to_sentence}" if @user.new_record?
      end
    end

    it 'increments User#count' do
      @creating_user.should change(User, :count).by(1)
    end

    it 'starts in pending state' do
      @creating_user.call
      @user.reload
      @user.should be_pending
    end
  end

  #
  # Validations
  #

  it 'requires password' do
    lambda do
      u = create_user(:password => nil)
      u.state = 'pending'
      u.should_not be_valid
      u.errors.on(:password).should_not be_nil
    end.should_not change(User, :count)
  end

  it 'requires password confirmation' do
    lambda do
      u = create_user(:password_confirmation => nil)
      u.errors.on(:password_confirmation).should_not be_nil
    end.should_not change(User, :count)
  end

  it 'does not require a password for passive users' do
    u = create_user(:password => nil)
    u.state = 'passive'
    u.should be_valid
  end

  it 'requires email' do
    lambda do
      u = create_user(:email => nil)
      u.errors.on(:email).should_not be_nil
    end.should_not change(User, :count)
  end

  describe 'allows legitimate emails:' do
    ['foo@bar.com', 'foo@newskool-tld.museum', 'foo@twoletter-tld.de', 'foo@nonexistant-tld.qq',
     'r@a.wk', '1234567890-234567890-234567890-234567890-234567890-234567890-234567890-234567890-234567890@gmail.com',
     'hello.-_there@funnychar.com', 'uucp%addr@gmail.com', 'hello+routing-str@gmail.com',
     'domain@can.haz.many.sub.doma.in', 'student.name@university.edu'
    ].each do |email_str|
      it "'#{email_str}'" do
        lambda do
          u = create_user(:email => email_str)
          u.errors.on(:email).should     be_nil
        end.should change(User, :count).by(1)
      end
    end
  end

  describe 'disallows illegitimate emails' do
    ['!!@nobadchars.com', 'foo@no-rep-dots..com', 'foo@badtld.xxx', 'foo@toolongtld.abcdefg',
     'Iñtërnâtiônàlizætiøn@hasnt.happened.to.email', 'need.domain.and.tld@de', "tab\t", "newline\n",
     'r@.wk', '1234567890-234567890-234567890-234567890-234567890-234567890-234567890-234567890-234567890@gmail2.com',
     # these are technically allowed but not seen in practice:
     'uucp!addr@gmail.com', 'semicolon;@gmail.com', 'quote"@gmail.com', 'tick\'@gmail.com', 'backtick`@gmail.com', 'space @gmail.com', 'bracket<@gmail.com', 'bracket>@gmail.com'
    ].each do |email_str|
      it "'#{email_str}'" do
        lambda do
          u = create_user(:email => email_str)
          u.errors.on(:email).should_not be_nil
        end.should_not change(User, :count)
      end
    end
  end

  describe 'allows legitimate names:' do
    ['Andre The Giant (7\'4", 520 lb.) -- has a posse',
     '', '1234567890_234567890_234567890_234567890_234567890_234567890_234567890_234567890_234567890_234567890',
    ].each do |name_str|
      it "'#{name_str}'" do
        lambda do
          u = create_user(:name => name_str)
          u.errors.on(:name).should     be_nil
        end.should change(User, :count).by(1)
      end
    end
  end

  describe "disallows illegitimate names" do
    ["tab\t", "newline\n",
     '1234567890_234567890_234567890_234567890_234567890_234567890_234567890_234567890_234567890_234567890_',
     ].each do |name_str|
      it "'#{name_str}'" do
        lambda do
          u = create_user(:name => name_str)
          u.errors.on(:name).should_not be_nil
        end.should_not change(User, :count)
      end
    end
  end

  describe "updating details" do
    it 'sets a new password if a password was given' do
      quentin = users(:quentin)
      quentin.password = 'new password'
      quentin.password_confirmation = 'new password'
      quentin.save!
      User.authenticate('quentin@example.com', 'new password').should == users(:quentin)
    end

    it 'does not change password if none was given' do
      users(:quentin).update_attributes(:password => '', :password_confirmation => '').should be_true
      User.authenticate('quentin@example.com', 'monkey').should == users(:quentin)
    end

    it 'does not rehash password' do
      users(:quentin).update_attributes(:name => 'I am Quentin')
      User.authenticate('quentin@example.com', 'monkey').should == users(:quentin)
    end

#    it 'does not immediately update an email address' do
#      users(:quentin).update_attributes(:email => 'quentin2@gmail.com')
#      User.authenticate('quentin2@gmail.com', 'monkey').should be_nil
#    end
  end

  #
  # Authentication
  #

  it 'authenticates user' do
    User.authenticate('quentin@example.com', 'monkey').should == users(:quentin)
  end

  it "doesn't authenticate user with bad password" do
    User.authenticate('quentin@example.com', 'invalid_password').should be_nil
  end

 if REST_AUTH_SITE_KEY.blank?
   # old-school passwords
   it "authenticates a user against a hard-coded old-style password" do
     User.authenticate('old_password_holder', 'test').should == users(:old_password_holder)
   end
 else
   it "doesn't authenticate a user against a hard-coded old-style password" do
     User.authenticate('old_password_holder', 'test').should be_nil
   end

   # New installs should bump this up and set REST_AUTH_DIGEST_STRETCHES to give a 10ms encrypt time or so
   desired_encryption_expensiveness_ms = 0.1
   it "takes longer than #{desired_encryption_expensiveness_ms}ms to encrypt a password" do
     test_reps = 100
     start_time = Time.now; test_reps.times{ User.authenticate('quentin@example.com', 'monkey'+rand.to_s) }; end_time   = Time.now
     auth_time_ms = 1000 * (end_time - start_time)/test_reps
     auth_time_ms.should > desired_encryption_expensiveness_ms
   end
 end

  #
  # Authentication
  #

  it 'sets remember token' do
    users(:quentin).remember_me
    users(:quentin).remember_token.should_not be_nil
    users(:quentin).remember_token_expires_at.should_not be_nil
  end

  it 'unsets remember token' do
    users(:quentin).remember_me
    users(:quentin).remember_token.should_not be_nil
    users(:quentin).forget_me
    users(:quentin).remember_token.should be_nil
  end

  it 'remembers me for one week' do
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    users(:quentin).remember_token.should_not be_nil
    users(:quentin).remember_token_expires_at.should_not be_nil
    users(:quentin).remember_token_expires_at.between?(before, after).should be_true
  end

  it 'remembers me until one week' do
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    users(:quentin).remember_token.should_not be_nil
    users(:quentin).remember_token_expires_at.should_not be_nil
    users(:quentin).remember_token_expires_at.should == time
  end

  it 'remembers me default two weeks' do
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    users(:quentin).remember_token.should_not be_nil
    users(:quentin).remember_token_expires_at.should_not be_nil
    users(:quentin).remember_token_expires_at.between?(before, after).should be_true
  end

  it 'registers passive user' do
    user = create_user(:password => nil, :password_confirmation => nil)
    user.should be_passive
    user.password = 'new password'
    user.password_confirmation = 'new password'
    user.save!
    # user.register! -- now happens automatically
    user.should be_pending
  end

  it 'suspends user' do
    users(:quentin).suspend!
    users(:quentin).should be_suspended
  end

  it 'does not authenticate suspended user' do
    users(:quentin).suspend!
    lambda{ User.authenticate('quentin@example.com', 'monkey') }.should raise_error(User::UserSuspended)
  end

  it 'deletes user' do
    users(:quentin).deleted_at.should be_nil
    users(:quentin).delete!
    users(:quentin).deleted_at.should_not be_nil
    users(:quentin).should be_deleted
  end

  describe "being unsuspended" do
    fixtures :users

    before do
      @user = users(:quentin)
      @user.suspend!
    end

    it 'reverts to active state' do
      @user.unsuspend!
      @user.should be_active
    end
  end
  
  describe "#same_customer_as?" do
    before do
      @user1 = create_user
      @user2 = create_user :email => 'quire2@example.com'
      @customer1 = Customer.new :name => 'Widgets Inc', :subdomain => 'widgets'
      @customer2 = Customer.new :name => 'Frobs Inc', :subdomain => 'frobs'
      @customer1.users << @user1
      @customer2.users << @user2
      @customer1.save!
      @customer2.save!
      @user1.reload
      @user2.reload
    end

    it 'should return true for the same user' do
      @user1.same_customer_as?(@user1).should be_true
    end
    
    it 'should return true for another user in the same customer' do
      @customer1.users << @user2
      @user1.same_customer_as?(@user2).should be_true
    end
    
    it 'should return false for when the other user does not have any customers in common' do
      @user1.same_customer_as?(@user2).should be_false
    end
  end

  describe "#can_edit_user?" do
    before do
      @admin = create_user :email => 'admin@example.com'
      @user1 = create_user :email => 'user1@example.com'
      @user2 = create_user :email => 'user2@example.com'
      @other = create_user :email => 'other@example.org'
      @customer = Customer.new :subdomain => 'example'
      @othercus = Customer.new :subdomain => 'other'
      CustomerUser.new(:customer => @customer, :user => @admin, :role => 'admin').save!
      @customer.users << [@user1, @user2]
      @othercus.users << [@other]
      [@customer, @othercus].each{|c| c.save! }
      [@admin, @user1, @user2, @other].each{|u| u.reload}
    end

    it "should allow a normal user to edit themselves" do
      @user1.can_edit_user?(@user1, @customer).should be_true
    end

    it "should allow an admin to edit themselves" do
      @admin.can_edit_user?(@admin, @customer).should be_true
    end

    it "should allow an admin to edit another user in the same customer" do
      @admin.can_edit_user?(@user1, @customer).should be_true
    end

    it "should not allow a normal user to edit another normal user" do
      @user1.can_edit_user?(@user2, @customer).should be_false
    end

    it "should not allow a normal user to edit an admin user" do
      @user1.can_edit_user?(@admin, @customer).should be_false
    end

    it "should not allow an admin to edit a user in another customer" do
      @admin.can_edit_user?(@other, @othercus).should be_false
    end
  end
  
  describe '#email=' do
    it 'should use the part before the @ sign' do
      record = User.new :email => 'joe.bloggs@example.com'
      record.name.should == 'Joe Bloggs'
    end
  
    it 'should not override a manually specified name with a guess' do
      record = User.new :email => 'joe@example.com', :name => 'Joe Bloggs'
      record.name.should == 'Joe Bloggs'
    end
  end

  describe '#password_reset_email!' do
    before :each do
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    it 'should send out a password recovery email' do
      users(:quentin).password_reset_email!

      ActionMailer::Base.deliveries.size.should == 1
      mail = ActionMailer::Base.deliveries[0]
      mail.to.should include('quentin@example.com')
      mail.body.should =~ /reset your password/
      extract_token_code = /https?:\/\/#{Rails::configuration.domain_name}\/(\w+)/
      mail.body.should =~ extract_token_code

      mail.body =~ extract_token_code
      token = Token::PasswordReset.find_by_code $1
      token.should_not be_nil
      token.should be_a_valid_token
      token.user.should == users(:quentin)
    end
  end

protected
  def create_user(options = {})
    options = {:email => 'quire@example.com', :password => 'quire69', :password_confirmation => 'quire69' }.merge(options)
    record = User.new(options)
    record.password = options[:password] # not mass assignable
    record.password_confirmation = options[:password_confirmation]
    record.register!
    record
  end
end
