require File.dirname(__FILE__) + '/../../spec_helper'
describe Token::Base do

  class Token::Test < Token::Base
  end
  class Token::Other < Token::Base
  end

  before :each do
    @token = Token::Test.new(:code => "test")
    @token.should be_valid
    @token.save!
  end

  it "should recognise when a token can be used no more" do
    Token::Base.new(:max_uses => 1, :use_count => 1).overused?.should == true
    Token::Base.new(:max_uses => 1, :use_count => 2).overused?.should == true
    Token::Base.new(:max_uses => 2, :use_count => 1).overused?.should == false
    Token::Base.new(:max_uses => nil, :use_count => 51).overused?.should == false
  end

  it "should recognise when a token is out of date" do
    Token::Base.new(:expires => 100.years.ago).expired?.should == true
    Token::Base.new(:expires => 1.second.ago).expired?.should == true
    Token::Base.new(:expires => 1.second.from_now).expired?.should == false
    Token::Base.new(:expires => 100.years.from_now).expired?.should == false
    Token::Base.new(:expires => nil).expired?.should == false
  end

  it "should return a per-subclass singleton for invalid token" do
    Token::Base.invalid_token.should equal(Token::Base.invalid_token)
    Token::Test.invalid_token.should equal(Token::Test.invalid_token)
    Token::Test.invalid_token.kind_of?(Token::Test).should == true
    Token::Base.invalid_token.kind_of?(Token::Test).should == false
  end

  it "should increment the use-count on use!" do
    @token.use_count.should == 0
    @token.transaction do
      @token.valid_token?
      @token.use!
    end
    @token.use_count.should == 1
  end

  it "should save the token on use!" do
    @token.transaction do
      @token.valid_token?
      @token.use!
    end
    @token.changed?.should == false 
    @token.use_count += 1
    @token.changed?.should == true
  end

  it "should throw an error if used without a valid_token? check" do
    lambda { @token.use! }.should raise_error
    lambda {
    @token.transaction do
      @token.use!.should throw_error
    end
    }.should raise_error
    lambda {
    @token.transaction do
      @token.valid_token?
      @token.use!
    end
    }.should_not raise_error
  end

  it "should be valid unless it is expired" do
    @token.expires = 5.minutes.ago
    @token.valid_token?.should == false
    @token.should have_an.error
    @token.expires = 5.minutes.from_now
    @token.valid_token?.should == true
    @token.expires = nil
    @token.valid_token?.should == true
  end

  it "should be valid unless it is overused" do
    @token.use_count = @token.max_uses
    @token.valid_token?.should == false
    @token.should have_an.error
    @token.use_count = @token.max_uses + 2
    @token.valid_token?.should == false
    @token.max_uses = @token.use_count + 2
    @token.valid_token?.should == true
    @token.max_uses = nil
    @token.valid_token?.should == true
  end

  it "should create a really invalid token" do
    Token::Test.invalid_token.valid_token?.should == false
    Token::Base.invalid_token.valid_token?.should == false
    token = Token::Test.invalid_token
    lambda { token.transaction do
      token.valid_token?
      token.use!
    end }.should raise_error
  end

  it "should find a token by correct class" do
    Token::Test.find_by_code('test').should == @token
    Token::Base.find_by_code('test').should == @token
    Token::Other.find_by_code('test').should == Token::Other.invalid_token
  end

  it "should return an invalid token when one could not be found" do
    Token::Test.find_by_code('tast').should == Token::Test.invalid_token
  end

end
