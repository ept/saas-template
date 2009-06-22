Users want to know that nobody can masquerade as them.  We want to extend trust
only to visitors who present the appropriate credentials.  Everyone wants this
identity verification to be as secure and convenient as possible.

Story: Logging in
  As an anonymous user with an account
  I want to log in to my account
  So that I can be myself

  Scenario: Anonymous user can get a login form on the main site
    Given an anonymous user
    When she goes to /login
    Then she should be at the new sessions page
    And the page should look AWESOME
    And she should see a <form> containing a textfield: Email, password: Password, and submit: 'Log in'

  Scenario: Anonymous user can get a login form on a customer's subdomain
    Given an anonymous user
    And a customer with subdomain: 'customer' exists
    When she goes on subdomain customer to /
    Then she should be redirected to /login
    When she follows that redirect!
    Then she should see a <form> containing a textfield: Email, password: Password, and submit: 'Log in'

  Scenario: Anonymous user with only one customer is redirected to customer's subdomain on login
    Given an anonymous user
    And an activated user with email: 'user@example.com' exists
    And 'user@example.com' is a user of only one company with subdomain 'customer'
    When he logs in with email: 'user@example.com', password: 'asdfasdf' on 'go-test.it'
    Then he should be on subdomain customer at ''
    And user@example.com should be logged in
    And he should not have an auth_token cookie

  Scenario: Anonymous user with multiple customers is given a choice of account
    Given an anonymous user
    And an activated user with email: 'user@example.com' exists
    And 'user@example.com' is a user of companies with subdomains 'customer1', 'customer2'
    When he logs in with email: 'user@example.com', password: 'asdfasdf' on 'go-test.it'
    Then he should see links to Customer1 and Customer2
    When he follows the link to Customer2
    Then user@example.com should be logged in
    And he should be on subdomain customer2 at ''

  Scenario: Anonymous user who logs in via customer subdomain stays on that customer
    Given an anonymous user
    And an activated user with email: 'user@example.com' exists
    And 'user@example.com' is a user of companies with subdomains 'customer1', 'customer2'
    When he logs in with email: 'user@example.com', password: 'asdfasdf' on 'customer2.go-test.it'
    Then user@example.com should be logged in
    And he should be on subdomain customer2 at ''

  Scenario: Anonymous user can log in and be remembered
    Given an anonymous user
    And an activated user with email: 'user@example.com' exists
    And 'user@example.com' is a user of only one company with subdomain 'customer'
    When she logs in with email: 'user@example.com', password: 'asdfasdf', remember me: '1' on 'customer.go-test.it'
    Then user@example.com should be logged in
    And she should have an auth_token cookie
    And she should be on subdomain customer at ''
  
  Scenario: User who has chosen their details to be remembered is logged in automatically
    Given an anonymous user
    And 'user@example.com' is a user of only one company with subdomain 'customer'
    And this browser has an auth_token cookie valid for user@example.com
    When he goes on subdomain customer to /
    Then user@example.com should be logged in
    And she should have an auth_token cookie
    And she should be on subdomain customer at ''

  Scenario: Logged in user can log out.
    Given an activated user with email: 'user@example.com' exists
    And 'user@example.com' is a user of only one company with subdomain 'customer'    
    And 'user@example.com' is logged in
    When she goes to /logout
    Then she should be redirected to 'http://customer.example.com/login'
    When she follows that redirect!
    Then she should see a notice message 'You have been logged out.'
    And she should not be logged in
    And she should not have an auth_token cookie
    And her session store should not have user_id
