require File.dirname(__FILE__) + '/../spec_helper'
describe Customer do

  before :each do
    @ept = Customer.new(:name => "Ept computing", :subdomain => "EPT")
  end

  it "should have a subdomain" do
    @ept.subdomain = ""
    @ept.should have_at_least(1).error_on :subdomain
  end

  it "should lowercase subdomain" do
    @ept.subdomain.should == "ept"
  end

  it "may have any valid subdomain" do
    @ept.subdomain = "hello"
    @ept.should_not have_an.error_on(:subdomain)
    @ept.subdomain = "aaa"
    @ept.should_not have_an.error_on(:subdomain)
    @ept.subdomain = "o-o"
    @ept.should_not have_an.error_on(:subdomain)
    @ept.subdomain = "ept-computing-gotest-it-testing"
    @ept.should_not have_an.error_on(:subdomain)
  end

  it "must have a valid subdomain" do
    @ept.subdomain = "hi"
    @ept.should have_an.error_on(:subdomain)
    @ept.subdomain = "1hgh"
    @ept.should have_an.error_on(:subdomain)
    @ept.subdomain = "high-"
    @ept.should have_an.error_on(:subdomain)
    @ept.subdomain = "-what"
    @ept.should have_an.error_on(:subdomain)
    @ept.subdomain = "a" * 64
    @ept.should have_an.error_on(:subdomain)
  end

end
