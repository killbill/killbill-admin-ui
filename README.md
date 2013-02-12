[![Build Status](https://travis-ci.org/killbill/killbill-admin-ui.png?branch=master)](https://travis-ci.org/killbill/killbill-admin-ui)
[![Code Climate](https://codeclimate.com/github/killbill/killbill-admin-ui.png)](https://codeclimate.com/github/killbill/killbill-admin-ui)

Getting started
===============

Running Kaui
------------

You can run Kaui locally using the dummy app in the test directory:

    # Point to your killbill installation
    export KILLBILL_URL="http://killbill.company.com:8080"
    cd test/dummy && rails s


Mounting Kaui into your own Rails app
-------------------------------------

The Kaui gem comes with a `kaui` script to mount it in your existing Rails app. See the [Getting Started](http://killbilling.org/start.html#kaui_deployment) guide.

Kaui expects the container app to define the <tt>current_user</tt> method, which returns the
name of the logged-in user. This is used by Killbill for auditing purposes.

Finally, Killbill server needs to be running for Kaui to fetch its information. Set the `KILLBILL_URL`
variable to point to your existing Killbill installation (e.g. http://killbill.company.com:8080).


Running tests
-------------

Prepare a kaui_test database locally to be able to run the test suite:

    create database kaui_test;
    grant all privileges on kaui_test.* to 'root'@'localhost' identified by '';

You can run tests using rake:

    rake test


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
