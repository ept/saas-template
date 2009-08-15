require File.dirname(__FILE__) + '/../spec_helper'

# Be sure to include AuthenticatedTestHelper in spec/spec_helper.rb instead
# Then, you can remove it from this and the units test.
include AuthenticatedTestHelper
include AuthenticatedSystem
def action_name() end

describe SessionsController do
  fixtures :users
  
  before do
    # FIXME -- sessions controller not testing xml logins 
    stub!(:authenticate_with_http_basic).and_return nil
  end    
  describe "logout_killing_session!" do
    before do
      login_as :quentin
      stub!(:reset_session)
    end
    it 'resets the session'         do should_receive(:reset_session);         logout_killing_session! end
    it 'kills my auth_token cookie' do should_receive(:kill_remember_cookie!); logout_killing_session! end
    it 'nils the current user'      do logout_killing_session!; current_user.should be_nil end
    it 'kills :user_id session' do
      session.stub!(:[]=)
      session.should_receive(:[]=).with(:user_id, nil).at_least(:once)
      logout_killing_session!
    end
    it 'forgets me' do    
      current_user.remember_me
      current_user.remember_token.should_not be_nil; current_user.remember_token_expires_at.should_not be_nil
      User.find(1).remember_token.should_not be_nil; User.find(1).remember_token_expires_at.should_not be_nil
      logout_killing_session!
      User.find(1).remember_token.should     be_nil; User.find(1).remember_token_expires_at.should     be_nil
    end
  end

  describe "logout_keeping_session!" do
    before do
      login_as :quentin
      stub!(:reset_session)
    end
    it 'does not reset the session' do should_not_receive(:reset_session);   logout_keeping_session! end
    it 'kills my auth_token cookie' do should_receive(:kill_remember_cookie!); logout_keeping_session! end
    it 'nils the current user'      do logout_keeping_session!; current_user.should be_nil end
    it 'kills :user_id session' do
      session.stub!(:[]=)
      session.should_receive(:[]=).with(:user_id, nil).at_least(:once)
      logout_keeping_session!
    end
    it 'forgets me' do    
      current_user.remember_me
      current_user.remember_token.should_not be_nil; current_user.remember_token_expires_at.should_not be_nil
      User.find(1).remember_token.should_not be_nil; User.find(1).remember_token_expires_at.should_not be_nil
      logout_keeping_session!
      User.find(1).remember_token.should     be_nil; User.find(1).remember_token_expires_at.should     be_nil
    end
  end
  
  describe 'When logged out' do 
    it "should not be authorized?" do
      authorized?().should be_false
    end    
  end

  #
  # Cookie Login
  #
  describe "Logging in by cookie" do
    def set_remember_token token, time
      @user[:remember_token]            = token; 
      @user[:remember_token_expires_at] = time
      @user.save!
    end    
    before do 
      @user = User.find(:first); 
      set_remember_token 'hello!', 5.minutes.from_now
    end    
    it 'logs in with cookie' do
      stub!(:cookies).and_return({ :auth_token => 'hello!' })
      logged_in?.should be_true
    end
    
    it 'fails cookie login with bad cookie' do
      should_receive(:cookies).at_least(:once).and_return({ :auth_token => 'i_haxxor_joo' })
      logged_in?.should_not be_true
    end
    
    it 'fails cookie login with no cookie' do
      set_remember_token nil, nil
      should_receive(:cookies).at_least(:once).and_return({ })
      logged_in?.should_not be_true
    end
    
    it 'fails expired cookie login' do
      set_remember_token 'hello!', 5.minutes.ago
      stub!(:cookies).and_return({ :auth_token => 'hello!' })
      logged_in?.should_not be_true
    end
  end

  # Other AuthenticatedSystem methods
  describe "#redirect_back_or_default" do
    it 'should redirect to the default if no return_to parameter is given' do
      should_receive(:params).at_least(:once).and_return({})
      should_receive(:redirect_to).with('/foo')
      redirect_back_or_default '/foo'
    end

    it 'should redirect to the return_to path' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah'})
      request.should_receive(:host_with_port).at_least(:once).and_return('test.host')
      should_receive(:redirect_to).with('http://test.host/blah')
      redirect_back_or_default '/foo'
    end

    it 'should append extra parameters to the return_to path' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah'})
      request.should_receive(:host_with_port).at_least(:once).and_return('test.host')
      should_receive(:redirect_to).with('http://test.host/blah?cow=moo')
      redirect_back_or_default '/foo', :cow => 'moo'
    end

    it 'should append extra parameters to the return_to path if return_to has existing query parameters' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah?sheep=baa'})
      request.should_receive(:host_with_port).at_least(:once).and_return('test.host')
      should_receive(:redirect_to).with('http://test.host/blah?sheep=baa&cow=moo')
      redirect_back_or_default '/foo', :cow => 'moo'
    end

    it 'should apply the subdomain option to the return_to URL' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah'})
      request.should_receive(:host_with_port).at_least(:once).and_return('test.host')
      should_receive(:redirect_to).with('http://yippee.test.host/blah')
      redirect_back_or_default '/foo', :subdomain => 'yippee'
    end

    it 'should apply the protocol option to the return_to URL' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah'})
      request.should_receive(:host_with_port).at_least(:once).and_return('secure.test.host')
      should_receive(:redirect_to).with('https://secure.test.host/blah')
      redirect_back_or_default '/foo', :protocol => 'https'
    end

    it 'should preserve the current port number' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah'})
      request.should_receive(:host_with_port).at_least(:once).and_return('test.host:3000')
      should_receive(:redirect_to).with('http://badger.test.host:3000/blah')
      redirect_back_or_default '/foo', :subdomain => 'badger'
    end

    it 'should preserve the current protocol' do
      should_receive(:params).at_least(:once).and_return({:return_to => '/blah'})
      request.should_receive(:host_with_port).at_least(:once).and_return('secure.example.com:443')
      request.should_receive(:protocol).at_least(:once).and_return('https')
      should_receive(:redirect_to).with('https://secure.example.com:443/blah')
      redirect_back_or_default '/foo'
    end

    describe 'with invalid return_to value' do
      ["/hey\n/you", "http://www.google.com/", "../moo", "/hey what's this?"].each do |attempt|
        it "should ignore #{attempt.inspect}" do
          should_receive(:params).at_least(:once).and_return({:return_to => attempt})
          should_receive(:redirect_to).with('/foo')
          redirect_back_or_default '/foo'
        end
      end
    end
  end
end
