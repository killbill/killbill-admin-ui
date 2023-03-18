# Rails 6.0.6 upgrade


Upgrade issues
-----------------------

| Tag          | Description | Status          |
| -----------: | ------------| -----------: |
| tests      |  Uncomment tests from `test/functional/kaui/admin_tenants_controller_test.rb`, `test/functional/kaui/admin_allowed_users_controller_test.rb`, `test/functional/kaui/invoices_controller_test.rb`       | pending
| kpm_macos      |  To resolve [test_paid_invoice](https://github.com/kpbacode/killbill-admin-ui/issues/10) I need to setup KPM on MacOS, probably payment_test_plugin is not installed properly     | pending
| kenui | Merge changes from https://github.com/kpbacode/killbill-email-notifications-ui.git | pending
| bug | https://github.com/kpbacode/killbill-admin-ui/issues/3 | pending
| bug | https://github.com/kpbacode/killbill-admin-ui/issues/4 | pending
| bug | https://github.com/kpbacode/killbill-admin-ui/issues/5 | pending
| bug | https://github.com/kpbacode/killbill-admin-ui/issues/8 | pending
| bug | https://github.com/kpbacode/killbill-admin-ui/issues/9 | pending
| bug | Chrome JS console errors | pending
| ruby | Ruby 3.x compatibility to enable JRuby CI jobs | pending

Notes
------------

Ruby 2.7.6+ or JRuby 9.1.14.0+ required.

# Rails 7.x upgrade

To be done...
