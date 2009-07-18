# This module defines custom variables which can be set in config/environment.rb or
# config/environments/*.rb to make parts of the application behave differently
# in each environment.
# The values of config variables thus set can be read from 
# Rails::configuration.config_variable_name

module Rails
  class Configuration
    # Should the login and signup pages redirect to a HTTPS url?
    attr_accessor :https_login

    # Base domain name; e.g. if this is "example.com", a customer's subdomain will
    # be "customername.example.com". Needs to be set explicitly in each environment.
    attr_accessor :domain_name
  end
end
