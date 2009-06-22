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

Add the following line to `config/environment.rb`:

    config.gem "rubyist-aasm", :lib => 'aasm', :source => "http://gems.github.com"

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
    map.root :controller => "about", :conditions => { :subdomain => nil} # http://localhost/
    map.root :controller => "about", :conditions => { :subdomain => "go-test"} # http://go-test.it/
    map.root :controller => "customers"


Then continue:

    $ git submodule init
    $ git submodule update
    $ rake db:migrate
    $ rake spec
    $ rake features

That should be everything up and running!
