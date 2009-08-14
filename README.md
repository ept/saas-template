Software-as-a-Service (SaaS) Rails template
===========================================

Using this template in your application:

    $ rails --database mysql myapp
    $ cd myapp
    $ rm -r README test     # we use RSpec rather than Test::Unit
    $ git init
    $ git add .
    $ git commit -m 'Auto-generated Rails project'
    $ git remote add saas git@github.com:ept/saas-template.git
    $ git pull saas master

Resolve any merge conflicts, then do `git commit -a`. When that is done, make sure git
has downloaded all required submodules:

    $ git submodule init
    $ git submodule update

Create databases `myapp_development` and `myapp_test` (or whatever you called the app),
tweak database config if necessary.

Add the following to `config/environment.rb` just after the `require File.join(File.dirname(__FILE__), 'boot')` line:

    # Include our custom configuration parameters (see lib/environment_config.rb)
    require 'environment_config'

and in the same file inside the `Rails::Initializer.run` block:

    config.gem "rubyist-aasm", :lib => 'aasm', :source => "http://gems.github.com"
    config.active_record.observers = :mailing_observer

Add the following to `config/environments/development.rb`:

    # Do not redirect to HTTPS URLs during development
    config.https_login = false

    # Set the base domain name under which our site is hosted
    config.domain_name = 'example.local'

Add the following to `config/environments/test.rb`:

    # Do not redirect to HTTPS URLs while testing
    config.https_login = false

    # Set the base domain name under which our site is hosted
    config.domain_name = 'test.host'

Add the following to `config/environments/production.rb`:

    # People to pester if an unhandled exception occurs
    ExceptionNotifier.exception_recipients = %w(admin@example.com)

    # Set this to true if you want the login form to redirect to a https:// URL
    config.https_login = false

    # Set the base domain name under which our site is hosted
    config.domain_name = 'example.com' # Set to your real domain name!

Edit `config/initializers/site_keys.rb` and change the value for `REST_AUTH_SITE_KEY`
to something unique and random.

Run `script/console` and run the following code to ensure the fixtures are regenerated
for your new site key:

    def secure_digest(*args)
      Digest::SHA1.hexdigest(args.flatten.join('--'))
    end

    def make_token
      secure_digest(Time.now, (1..10).map{ rand.to_s })
    end

    def password_digest(password, salt)
      digest = REST_AUTH_SITE_KEY
      REST_AUTH_DIGEST_STRETCHES.times do
        digest = secure_digest(digest, salt, password, REST_AUTH_SITE_KEY)
      end
      digest
    end

    def options
      {:include_activation => true, :stateful => true}
    end

    f=File.new('vendor/plugins/restful_authentication/generators/authenticated/templates/spec/fixtures/users.yml', 'r')
    contents=f.read
    rendered = ERB.new(contents, nil, '-').result.gsub(/login/, 'name')
    File.open('spec/fixtures/users.yml', 'w'){|f| f.write(rendered)}


Edit `config/routes.rb` and add the following (assuming you have a marketing site exposed
by a controller called `AboutController`):

    map.logout   '/logout',   :controller => 'sessions',  :action => 'destroy'
    map.login    '/login',    :controller => 'sessions',  :action => 'new'
    map.register '/register', :controller => 'users',     :action => 'create'
    map.signup   '/signup',   :controller => 'customers', :action => 'new'
    map.welcome  '/welcome',  :controller => 'customers', :action => 'dashboard'
    map.forgotten_password '/forgotten_password', :controller => 'users', :action => 'forgotten_password'

    map.resources :users
    #map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete } # ???

    map.resource :session

    # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
    # For the top-level site we want the about controller, else we want the customers controller
    #
    # TODO: would be nicer to patch request_routing to interact with subdomain-fu and allow :subdomain => false
    map.root :controller => "about", :conditions => { :subdomain => nil}       # http://localhost/
    map.root :controller => "about", :conditions => { :subdomain => "example"} # http://example.com/
    if %w(production development).include? RAILS_ENV
      map.root :controller => "about", :conditions => { :subdomain => "www"}   # http://www.example.com/
    end
    map.root :controller => "customers" # customer subdomains

    # Default routes
    map.connect ':controller/:action/:id'
    map.connect ':controller/:action/:id.:format'

    # Map tokens to http://example.com/tokencode -- must be the last entry in routes.rb, after default routes
    map.connect ':code', :controller => 'tokens', :action => 'show'


Edit `config/environments/production.rb` and add:

    # Set this to true if you want the login form to redirect to a https:// URL
    config.https_login = false

    # Set the base domain name under which our site is hosted
    config.domain_name = 'example.com'


Edit `config/environtments/development.rb` and add:

    # Do not redirect to HTTPS URLs during development
    config.https_login = false

    # This name (and several subdomains of it) should be placed in your /etc/hosts, e.g:
    # 127.0.0.1 example.local www.example.local foo.example.local bar.example.local
    config.domain_name = 'example.local'


On your development machine, edit `/etc/hosts` and add a line like:

    127.0.0.1 example.local www.example.local foo.example.local bar.example.local baz.example.local


You may also need to edit `app/models/customer.rb` and add your domain name there
(`example` if your full domain name is `example.com`).


Edit `config/database.yml`: add `&TEST` to the line `test:` and append the following two lines:

    cucumber:
      <<: *TEST


Then run the tests:

    $ rake db:migrate
    $ rake spec
    $ rake features

That should be everything up and running!

If your `app/views/layouts` does not yet exist you will get some errors running cucumber
(`rake features`). You can fix them by adding a simple `app/views/layouts/application.html.erb`,
like the following:

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      <head>
        <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
        <title>Hello World!</title>
      </head>
      <body>
        <p style="color: green" id="flashNotice"><%= flash[:notice] %></p>
        <p style="color: red" id="flashError"><%= flash[:error] %></p>
        <%= yield %>
      </body>
    </html>
