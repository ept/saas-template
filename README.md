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

Resolve any merge conflicts, then do `git commit -a`. Create databases `myapp_development`
and `myapp_test` (or whatever you called the app), tweak database config if necessary.

Add the following line to `config/environment.rb` in the `Rails::Initializer.run` block:

    config.gem "rubyist-aasm", :lib => 'aasm', :source => "http://gems.github.com"

And add the following line right at the end of `config/environment.rb`:

    SubdomainFu.tld_sizes = {:development => 1, :test => 1, :production => 1 }

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


Edit `config/routes.rb` and add the following:

    map.logout '/logout', :controller => 'sessions', :action => 'destroy'
    map.login '/login', :controller => 'sessions', :action => 'new'
    map.register '/register', :controller => 'users', :action => 'create'
    map.signup '/signup', :controller => 'customers', :action => 'new'
    map.welcome '/welcome', :controller => 'customers', :action => 'dashboard'
    map.resources :users

    map.resource :session

    # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
    # For the top-level site we want the about controller, else we want the customers controller
    #
    # TODO: would be nicer to patch request_routing to interact with subdomain-fu and allow :subdomain => false
    map.root :controller => "customers", :conditions => { :subdomain => nil} # http://localhost/
    map.root :controller => "customers", :conditions => { :subdomain => "go-test"} # http://go-test.it/
    map.root :controller => "customers"


Edit each of in `config/environments/development.rb` and `production.rb`, adding a line:

    ActionController::Base.session_options[:domain] = "go-test.local"   # development.rb
    ActionController::Base.session_options[:domain] = "go-test.it"      # production.rb


Edit `config/database.yml`: add `&TEST` to the line `test:` and append the following two lines:

    cucumber:
      <<: *TEST


Then continue:

    $ git submodule init
    $ git submodule update
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
