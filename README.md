Getting started
===============

Kaui core mountable engine. For Kaui the UI, see [killbill-admin-ui-standalone](https://github.com/killbill/killbill-admin-ui-standalone).

Kill Bill compatibility
-----------------------

| Kaui version | Kill Bill version |
| -----------: |------------------:|
| 0.14.y       |            0.16.z |
| 0.15.y       |  0.18.z (Rails 4) |
| 0.16.y       |  0.18.z (Rails 5) |
| 1.x.y        |  0.20.z (Rails 5) |
| 2.x.y        |  0.22.z (Rails 5) |
| 3.x.y        |  0.24.z (Rails 7) |

Dependencies
------------

Ruby 3.2.2+ or JRuby 9.4.2.0+ required.

Running Kaui locally
---------------------

Note: use Ruby, not JRuby, for running the app locally.

You can run Kaui locally by using the test/dummy app provided:

```
export RAILS_ENV=development DB_HOST=127.0.0.1 DB_USER=root DB_PASSWORD=root DB_PORT=3306
bundle install
bundle exec rails db:migrate
bundle exec rails s
```

The Kill Bill URL can be configured through the `KILLBILL_URL` environment variable, e.g.

```
KILLBILL_URL='http://killbill.acme:8080'
```

Mounting Kaui into your own Rails app
-------------------------------------

The Kaui gem comes with a `kaui` script to mount it in your existing Rails app.

Kaui expects the container app to define the <tt>current_user</tt> method, which returns the
name of the logged-in user. This is used by Kill Bill for auditing purposes.

Migrations can be copied over to your app via:

```
bundle exec rake kaui:install:migrations
```

Finally, a Kill Bill server needs to be running for Kaui to fetch its information (see the Configuration section below).
The default login credentials are admin/password.  Users, Credentials, Roles and Permissions are
passed through to Kill Bill. It uses Basic Auth by default, but the backend is pluggable (LDAP,
ActiveDirectory, etc.).


Running tests
-------------

```
rails t
```

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


Multi-Tenancy
=============

KAUI has been enhanced to support multi-tenancy. In order to benefit from that mode, remove the properties `KillBillClient.api_key` and `KillBillClient.api_secret` from the config/initializers directory.

Admin User Roles
----------------

In multi-tenancy mode, there are two kinds of users:

* The **multi-tenant admin** user, which has the rights to configure the tenant information (creation of tenant, add allowed users for specific tenant, upload catalog, ...)
* The **per-tenant admin** user, which operates just a given tenant

Those roles and permissions are defined the same way other permissions are defined: The Shiro configuration (static config file, LDAP) in Kill Bill, will determine for each user its associated role, and the roles will have a set of available [permissions](https://github.com/killbill/killbill-api/blob/master/src/main/java/org/killbill/billing/security/Permission.java). The new permissions have been created:

* TENANT_CAN_VIEW
* TENANT_CAN_CREATE
* OVERDUE_CAN_UPLOAD
* CATALOG_CAN_UPLOAD

The [enforcement in KAUI](https://github.com/killbill/killbill-admin-ui/blob/master/app/models/kaui/ability.rb) is based on the CanCan gem.

Multi-tenancy screens
---------------------

KAUI has been enriched with new models and new screens to manage the multi-tenancy, and those are available for the multi-tenant admin user:

* The `kaui_tenants` table will list the available tenants (from KAUI point of view); note that this is redundant with the Kill Bill `tenants` table, and the reason is that the `api_secret` needs to be maintained in KAUI as well, so listing the existing tenants from Kill Bill would not work since that key is encrypted and cannot be returned. A new screen mounted on `/admin_tenants` allows to configure new tenants. The view allows to create the new tenant in Kill Bill or simply updates the local KAUI config if the tenant already exists.
* The `kaui_allowed_users` table along with the join table `kaui_allowed_user_tenants` will list all the users in the system that can access specific tenants. The join table is required since a given user could access multiple tenants (e.g multi-tenant admin user), and at the same time many users could access the same tenant. A new screen mounted on `/admin_allowed_users` allows to configure the set of allowed users associated to specific tenants.



