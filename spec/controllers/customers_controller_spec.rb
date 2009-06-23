require File.dirname(__FILE__) + '/../spec_helper'

describe CustomersController do

  def countable(arr)
    def arr.count
      size
    end
    arr
  end

  describe "when asked to choose a customer" do
    before :each do
      @ept = mock_model Customer, {:subdomain => "ept"}
      @corpus = mock_model Customer, {:subdomain => "corpus"}
      @hasni = mock_model User, {:customers => countable([@ept])}
      @newb = mock_model User, {:customers => countable([])}
      @marthynn = mock_model User, {:customers => countable([@ept, @corpus])}

      [@hasni, @newb, @marthynn].each do |user|
        [@ept, @corpus].each do |customer|
          CustomerUser.should_receive(:linked?).any_number_of_times.with(customer, user).and_return(user.customers.include?(customer))
        end
      end
    end

    it "should choose a linked current_customer" do
      controller.should_receive(:current_customer).any_number_of_times.and_return(@ept)
      controller.should_receive(:current_user).any_number_of_times.and_return(@hasni)
      get :choose
      response.should redirect_to("http://ept.test.host/welcome")
    end

    it "should choose the only possible customer" do
      controller.should_receive(:current_customer).any_number_of_times.and_return(nil)
      controller.should_receive(:current_user).any_number_of_times.and_return(@hasni)
      get :choose
      response.should redirect_to("http://ept.test.host/welcome")
    end

    it "should not choose an unlinked current_customer" do
      controller.should_receive(:current_customer).any_number_of_times.and_return(@corpus)
      controller.should_receive(:current_user).any_number_of_times.and_return(@hasni)
      get :choose
      response.should redirect_to("http://ept.test.host/welcome")
    end

    it "should redirect to new if there are no linked customers" do
      controller.should_receive(:current_customer).any_number_of_times.and_return(@ept)
      controller.should_receive(:current_user).any_number_of_times.and_return(@newb)
      get :choose
      response.should redirect_to("http://test.host/signup")
    end

    it "should present a choice dialogue when ambiguous" do
      controller.should_receive(:current_customer).any_number_of_times.and_return(nil)
      controller.should_receive(:current_user).any_number_of_times.and_return(@marthynn)
      get :choose
      response.should render_template("customers/choose.erb")
      assigns(:customers).should include(@corpus, @ept)
    end

  end

  describe "when creating a new user" do

    before :each do
      @params = {'subdomain' => "ept", 'invitation_code' => "ab48f", 'email' => "hasni@eptcomputing.com"}
      @signup = mock_model CustomerSignup, @params
    end

    it "should assign the customer_signup to the view" do
      CustomerSignup.should_receive(:new).any_number_of_times.with(nil).and_return(@signup)
      get :new
      assigns(:customer_signup).should == @signup
    end

    it "should allow params to be set as query arguments" do
      CustomerSignup.should_receive(:new).with({'email' => 'hasni@eptcomputing.com', 'invitation_code' => 'ab48f'}).and_return(@signup)
      get :new, :email => 'hasni@eptcomputing.com', :invitation_code => 'ab48f'
      assigns(:customer_signup).should == @signup
    end

    it "should pass parameters onto the model" do
      CustomerSignup.should_receive(:new).with(@params).and_return(@signup)
      @signup.should_receive(:valid?).and_return(true)
      post :new, :customer_signup => @params
      # FIXME: persuade rspec to somehow understand routing...
      response.should redirect_to("http://ept.test.host/users/new?email=hasni%40eptcomputing.com&invitation_code=ab48f")
    end

    it "should redisplay the page on error" do
      CustomerSignup.should_receive(:new).with(@params).and_return(@signup)
      @signup.should_receive(:valid?).any_number_of_times.and_return(false)
      post :new, :customer_signup => @params
      response.should render_template("customers/new.erb")
      assigns(:customer_signup).should == @signup
    end

  end
end
