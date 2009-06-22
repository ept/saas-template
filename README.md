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

Then continue:

    $ git submodule init
    $ git submodule update
    $ rake db:migrate
    $ rake spec
    $ rake features

That should be everything up and running!
