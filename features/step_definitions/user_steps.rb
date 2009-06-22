RE_User      = %r{(?:(?:the )? *(\w+) *)}
RE_User_TYPE = %r{(?: *(\w+)? *)}

#
# Setting
#

def create_user!(params)
  User.create_for_demo(params['email'], params['password'] || 'asdfasdf')
end


Given "an anonymous user" do
  log_out!
end

Given "$an $user_type user with $attributes exists" do |_, user_type, attributes|
  create_user! attributes.to_hash_from_story
end

Given "'$email' is logged in" do |email|
  log_in_user  'email' => email
end

Given "$an invitation token with code: '(.*)' exists" do |_, code|
  Token::Invitation.new(:code => code).save!
end

Given "there is no invitation token with code: '(.*)'" do |code|
  Token::Invitation.find_by_code(code).destroy! rescue nil
end

Given "a customer with $attributes exists" do |attributes|
  Customer.new(attributes.to_hash_from_story).save!
end

Given "'$email' is a user of (only one company|companies) with subdomains? $list" do |email, _, subdomains|
  user = User.find_by_email(email) || create_user!('email' => email)
  subdomains.to_array_from_story.each do |subdomain|
    customer = Customer.new(:subdomain => subdomain)
    customer.save!
    CustomerUser.new(:customer => customer, :user => user).save!
  end
end

Given "$actor has an auth_token cookie valid for (.*)" do |_, email|
  log_in_user 'email' => email, 'remember_me' => true
  request.cookies.delete "_frontend_session"
end
#
# Actions
#
When "$actor logs out" do
  log_out
end

When "$actor registers an account as the preloaded '$login'" do |_, login|
  user = named_user(login)
  user['password_confirmation'] = user['password']
  create_user user
end

When "$actor registers an account with $attributes" do |_, attributes|
  create_user attributes.to_hash_from_story
end

When "$actor logs in with $attributes on '(.*)'" do |_, attributes, domain|
  log_in_user attributes.to_hash_from_story.merge('subdomain' => domain.sub('go-test.it',''))
end

When "$actor follows the link to $title" do |_, title| 
  click_link title
end

# Form filling
When "$actor enters '(.*)' as (.*)" do |_, value, field|
  fill_in /#{field.gsub(' ','_')}/, :with => value
end

When "$actor clicks submit" do |_|
  click_button
end

When "$actor selects (.*)" do |_, sel|
  select sel
end

#
# Result
#
Then "$actor should be invited to sign in" do |_|
  response.should render_template('/sessions/new')
end

Then "$actor should not be logged in" do |_|
  controller.logged_in?.should_not be_true
end

Then "$actor should see links to $titles" do |_, titles|
  titles.to_array_from_story.each do |title| 
    response.body.should have_tag "a", :text => title
  end
end

Then "$email should be logged in" do |email|
  controller.current_user.email.should == email
end

Then "$actors current customer should have subdomain: '(.*)'" do |_, subdomain|
  controller.current_customer.subdomain.should == subdomain
end


#Then "$actor should see (a|an) $type message '(.*)'" do |_, _, type, message|
#
#end

def named_user login
  user_params = {
    'admin'   => {'id' => 1, 'login' => 'addie', 'password' => '1234addie', 'email' => 'admin@example.com',       },
    'oona'    => {          'login' => 'oona',   'password' => '1234oona',  'email' => 'unactivated@example.com'},
    'reggie'  => {          'login' => 'reggie', 'password' => 'monkey',    'email' => 'registered@example.com' },
    }
  user_params[login.downcase]
end

#
# User account actions.
#
# The ! methods are 'just get the job done'.  It's true, they do some testing of
# their own -- thus un-DRY'ing tests that do and should live in the user account
# stories -- but the repetition is ultimately important so that a faulty test setup
# fails early.
#

def log_out
  get '/sessions/destroy'
end

def log_out!
  log_out
  response.should redirect_to('/')
  follow_redirect!
end

def log_in_user(user_params)
  if user_params['subdomain']
    get "http://#{user_params['subdomain']}example.com/login"
  else
    get "/login"
  end
  fill_in :email, :with => user_params['email']
  fill_in :password, :with => user_params['pasword'] || 'asdfasdf'
  if user_params['remember_me'] then
    check :remember_me
  end
  click_button
end

