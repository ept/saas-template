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

Resolve any merge conflicts, then do `git commit`. Create databases `myapp_development`
and `myapp_test` (or whatever you called the app), tweak database config if necessary.

Then continue:

    $ git submodule init
    $ git submodule update
    $ rake db:migrate
    $ rake spec
    $ rake features

That should be everything up and running!
