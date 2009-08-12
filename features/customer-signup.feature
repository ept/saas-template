Customers are good. They give us business. However, we also don't want too many
customers at the same time, otherwise our systems get overloaded. We control
how many customers can sign up by issuing invitation codes.

Story: New customer signup
  As an anonymous user
  I want to sign up as a new customer
  So that I can start using this awesome application
  
  Scenario: Anonymous user can start creating a customer
    Given an anonymous user
    When he goes to /signup
    Then he should be at the 'customers/new' page
    And the page should look AWESOME
    And he should see a <form> containing a textfield: 'Choose your URL', textfield: 'Your email address', textfield: 'Invitation code', submit: 'Sign up for free'

  Scenario: New user can create a customer
    Given an anonymous user
    And no user with email: 'newuser@example.com' exists
    And no customer with subdomain: 'blah' exists
    And an invitation token with code: 'ab48d' exists
    When he goes to /signup
    And he enters 'blah' as subdomain
    And he enters 'newuser@example.com' as email
    And he enters 'ab48d' as invitation code
    And he clicks submit
    Then he should be on subdomain blah at 'users/new'
    Then he should see a <form> containing a textfield: 'Your name (optional)', password: 'Your new password', password: 'Confirm your password', textfield: 'Company name (optional)', submit: 'Set up account'
    When he enters 'asdfasdf' as password
    And he enters 'asdfasdf' as password_confirmation
    And he clicks submit
    Then he should be on subdomain blah at 'welcome'
    And newuser@example.com should be logged in

  Scenario: Existing user can create a customer
    Given an anonymous user
    And an activated user with email: 'user@example.com' and password: 'asdfasdf' exists
    And no customer with subdomain: 'blah' exists
    And an invitation token with code: 'ab48d' exists
    When she goes to /signup
    And she enters 'blah' as subdomain
    And she enters 'user@example.com' as email
    And she enters 'ab48d' as invitation code
    And she clicks submit
    Then she should be on subdomain blah at 'users/new'
    And she enters 'asdfasdf' as password
    And she clicks submit
    Then user@example.com should be logged in
    And she should be on subdomain blah at 'welcome'

  Scenario: Cannot create a customer with a name which already exists
    Given an anonymous user
    And a customer with subdomain: 'customer' exists
    And an invitation token with code: 'ab48d' exists
    When he goes to /signup
    And he enters 'customer' as subdomain
    And he enters 'newuser@example.com' as email
    And she enters 'ab48d' as invitation code
    And he clicks submit
    Then he should be at the 'customers/new' page
    And he should see a validation error 'Sorry, this subdomain has already been taken.'

  Scenario: Cannot create a customer without a valid invitation code
    Given an anonymous user
    And no customer with subdomain: 'blah' exists
    And there is no invitation token with code: 'ab48d'
    When he goes to /signup
    And he enters 'blah' as subdomain
    And he enters 'newuser@example.com' as email
    And she enters 'ab48d' as invitation code
    And he clicks submit
    Then he should be at the 'customers/new' page
    And he should see a validation error 'Sorry, we could not recognise this code.'

  Scenario: Invitation code can be taken from a URL keyword
    Given an anonymous user
    And no customer with subdomain: 'blah' exists
    And an invitation token with code: 'ab48d' exists
    When he goes to /ab48d
    And he goes to /signup
    And he enters 'blah' as subdomain
    And he enters 'me@example.com' as email
    And he clicks submit
    Then he should be on subdomain blah at 'users/new'
    Then he should see a <form> containing a textfield: 'Your name (optional)', password: 'Your new password', password: 'Confirm your password', textfield: 'Company name (optional)', submit: 'Set up account'
