require File.dirname(__FILE__) + '/../../spec_helper'
describe Token::Invitation do

  before :each do
    @token = Token::Invitation.new(:code => 'test')
  end
  
  it "should be valid for anything (for the moment)" do
    @token.valid_for?(Customer.new, User.new).should == true
  end

  it "should allow using after a valid_for? check" do
    @token.transaction do
      @token.valid_for?(Customer.new, User.new)
      @token.use!
    end
  end

end
