[![Build Status](https://travis-ci.org/killbill/killbill-admin-ui.png)](https://travis-ci.org/killbill/killbill-admin-ui)
[![Code Climate](https://codeclimate.com/github/killbill/killbill-admin-ui.png)](https://codeclimate.com/github/killbill/killbill-admin-ui)

Getting started
===============

Running Kaui
------------

You can run Kaui locally using the sandbox script:

    # Point to your killbill installation
    export KILLBILL_URL="http://killbill.company.com:8080"
    # Run the sandbox script
    bundle exec script/sandbox
    # Start the Rails app
    cd sandbox
    rails s


Mounting Kaui into your own Rails app
-------------------------------------

The Kaui gem comes with a `kaui` script to mount it in your existing Rails app.

Kaui expects the container app to define the <tt>current_user</tt> method, which returns the
name of the logged-in user. This is used by Killbill for auditing purposes.

Finally, Killbill server needs to be running for Kaui to fetch its information. Set the `KILLBILL_URL`
variable to point to your existing Killbill installation (e.g. http://killbill.company.com:8080).
The default login credentials are admin/password.  Users, Credentials, Roles and Permissions are 
passed through to Kill Bill. It uses Basic Auth by default, but the backend is pluggable (LDAP, 
ActiveDirectory, etc.).


Multi-Tenancy
-------------

If you are using Kaui against a single tenant, specify your api key and secret in ```config/initializers/killbill_client.rb```:

```
KillBillClient.url = 'http://127.0.0.1:8080/'
KillBillClient.api_key = 'bob'
KillBillClient.api_secret = 'lazar'
```

Sharing a Kaui instance across multiple tenants is not supported yet (you need to spawn one instance per tenant).


Running tests
-------------

Go into 'test/dummy': 
> cd test/dummy/

Run migrations:
> export RAILS_ENV=test
> rake kaui:install:migrations
> rake db:migrate

Run the tests:
(Move back to top level)
> cd ../..
> rake test

Note: functional and integration tests require an instance of Kill Bill to test against.

Development
===========

Working with the kaui script
----------------------------

In order to generate the Rubygems-friendly `kaui` script, you need to build the gem
and install it locally.

First, build the gem in the `pkg` directory:

    rake build

Then, install and run it from a local directory:

    mkdir foo
    gem install pkg/kaui-*.gem -i foo
    GEM_PATH=$PWD/foo:$GEM_PATH ./foo/bin/kaui /path/to/rails/app --path=$PWD --skip-bundle

Alternatively, you can run the `kaui` script under `bin` by setting your loadpath correctly:

    ruby -Ilib bin/kaui /path/to/rails/app --path=$PWD --skip-bundle
