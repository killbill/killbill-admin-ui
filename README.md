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

Kaui expects the container app to define the <tt>current_user</tt> method, which returns the
name of the logged-in user. This is used by Killbill for auditing purposes.

You also need to install validation.js into your asset pipeline.

Gem dependencies:

    gem 'rest-client', '~> 1.6.7'
    gem 'money-rails', '~> 0.5.0'


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
    gem install pkg/kaui-0.1.18.gem -i foo
    GEM_PATH=$PWD/foo:$GEM_PATH ./foo/bin/kaui

Alternatively, you can run the `kaui` script under `bin` by setting your loadpath correctly:

    ruby -Ilib bin/kaui /path/to/rails/app --path=$PWD --skip-bundle
