require File.dirname(__FILE__) + '/../spec_helper'

describe TokensController do
  before :each do
    @overused_token = Token::Base.new :code => 'knackered', :max_uses => 3, :use_count => 3
    @expired_token = Token::Base.new :code => 'that_was_yesterday', :expires => 1.day.ago
    @tracking_keyword = Token::TrackingKeyword.new :code => 'blah', :param => {:medium => 'blah', :campaign => 'launch'}

    controller.should_receive(:current_customer).any_number_of_times.and_return(nil)
    controller.should_receive(:current_user).any_number_of_times.and_return(nil)
  end

  describe "when accessing a token" do
    it "should respond with 404 if the token does not exist" do
      Token::Base.should_receive(:find).with(:first, :conditions => {:code => 'asdfasdfasdf'}).and_return(nil)
      lambda {
        get :show, :code => 'asdfasdfasdf'
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should give an error message if the token is overused" do
      Token::Base.should_receive(:find).with(:first, :conditions => {:code => 'knackered'}).and_return(@overused_token)
      get :show, :code => 'knackered'
      response.should redirect_to('/')
      flash[:error].should =~ /already been used/
    end

    it "should give an error message if the token has expired" do
      Token::Base.should_receive(:find).with(:first, :conditions => {:code => 'that_was_yesterday'}).and_return(@expired_token)
      get :show, :code => 'that_was_yesterday'
      response.should redirect_to('/')
      flash[:error].should =~ /expired/
    end

    it "should redirect to the URL specified by the handler if the token is valid" do
      Token::Base.should_receive(:find).with(:first, :conditions => {:code => 'blah'}).and_return(@tracking_keyword)
      get :show, :code => 'blah'
      response.should redirect_to({:controller => 'about', :action => 'index', :utm_source => 'url_keyword',
        :utm_medium => 'blah', :utm_campaign => 'launch'})
    end

    it "should store the token code in the session if the token is valid" do
      Token::Base.should_receive(:find).with(:first, :conditions => {:code => 'blah'}).and_return(@tracking_keyword)
      get :show, :code => 'blah'
      session[:token_code].should == 'blah'
    end
  end
end
