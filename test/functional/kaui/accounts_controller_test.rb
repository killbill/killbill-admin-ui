# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AccountsControllerTest < Kaui::FunctionalTestHelper
    test 'should get index' do
      get :index
      assert_response 200
    end

    test 'should get index one account' do
      parameters = {
        fast: '1',
        q: @account.account_id
      }

      get :index, params: parameters
      assert_response :redirect
      assert_redirected_to account_path(@account.account_id)

      parameters = {
        fast: '1',
        q: 'THIS_IS_NOT_FOUND_REDIRECT'
      }

      get :index, params: parameters
      assert_response :redirect
      assert_redirected_to home_path
    end

    test 'should list accounts' do
      # Test pagination
      get :pagination, params: { format: :json }
      verify_pagination_results!
    end

    test 'should search accounts' do
      # Test search
      get :pagination, params: { sSearch: 'foo', format: :json }
      verify_pagination_results!
    end

    test 'should handle Kill Bill errors when showing account details' do
      account_id = SecureRandom.uuid.to_s
      get :show, params: { account_id: }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{account_id} type=ACCOUNT doesn't exist!", flash[:error]
    end

    test 'should find account by id' do
      get :show, params: { account_id: @account.account_id }
      assert_response 200
      assert_not_nil assigns(:tags)
      assert_not_nil assigns(:account_emails)
      assert_not_nil assigns(:overdue_state)
      assert_not_nil assigns(:payment_methods)
    end

    test 'should check that overdue state is Good' do
      get :show, params: { account_id: @account.account_id }
      assert_response 200

      overdue_status_proc_count = 0

      assert_select 'table' do |tables|
        tables.each do |table|
          assert_select table, 'tr' do |rows|
            rows.each do |row|
              # find overdue status in the response
              is_overdue_state = false
              assert_select row, 'th' do |col|
                is_overdue_state = col[0].text.eql?('Overdue status')
              end

              # if found
              next unless is_overdue_state

              overdue_status_proc_count += 1
              assert_select row, 'td' do |col|
                assert_select col, 'span' do |content|
                  assert 'Good', content[0].text
                  overdue_status_proc_count += 1 if content[0].text.eql?('Good')
                end
              end
            end
          end
        end
      end

      # assert that overdue state is found with result equal to Good
      assert overdue_status_proc_count, 2
    end

    test 'should handle Kill Bill errors when creating account' do
      post :create
      assert_redirected_to home_path
      assert_equal 'Required parameter missing: account', flash[:error]

      external_key = SecureRandom.uuid.to_s
      post :create, params: { account: { external_key: } }
      assert_redirected_to account_path(assigns(:account).account_id)

      post :create, params: { account: { external_key: } }
      assert_template :new
      assert_equal "Error while creating account: Account already exists for key #{external_key}", flash[:error]
    end

    test 'should create account' do
      get :new
      assert_response 200
      assert_not_nil assigns(:account)

      post :create,
           params: {
             account: {
               name: SecureRandom.uuid.to_s,
               external_key: SecureRandom.uuid.to_s,
               email: "#{SecureRandom.uuid}@example.com",
               time_zone: '-06:00',
               country: 'AR',
               is_migrated: '1'
             }
           }
      assert_redirected_to account_path(assigns(:account).account_id)
      assert_equal 'Account was successfully created', flash[:notice]

      assert_equal '-06:00', assigns(:account).time_zone
      assert_equal 'AR', assigns(:account).country
      assert assigns(:account).is_migrated
    end

    test 'should update account' do
      get :edit, params: { account_id: @account.account_id }
      assert_response 200
      assert_not_nil assigns(:account)

      latest_account_attributes = assigns(:account).to_hash
      put :update,
          params: {
            account_id: @account.account_id,
            account: latest_account_attributes.merge({
                                                       name: SecureRandom.uuid.to_s,
                                                       email: "#{SecureRandom.uuid}@example.com"
                                                     })
          }
      assert_redirected_to account_path(assigns(:account).account_id)
      assert_equal 'Account successfully updated', flash[:notice]
    end

    test 'should be redirected if no payment_method_id is specified when setting default payment method' do
      put :set_default_payment_method, params: { account_id: @account.account_id }
      assert_redirected_to account_path(@account.account_id)
      assert_equal 'Required parameter missing: payment_method_id', flash[:error]
    end

    test 'should handle Kill Bill errors when setting default payment method' do
      account_id = SecureRandom.uuid.to_s
      put :set_default_payment_method, params: { account_id:, payment_method_id: @payment_method.payment_method_id }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{account_id} type=ACCOUNT doesn't exist!", flash[:error]
    end

    test 'should set default payment method' do
      put :set_default_payment_method, params: { account_id: @account.account_id, payment_method_id: @payment_method.payment_method_id }
      assert_response 302
    end

    test 'should handle Kill Bill errors when paying all invoices' do
      account_id = SecureRandom.uuid.to_s
      post :pay_all_invoices, params: { account_id: }
      assert_redirected_to home_path
      assert_equal "Error while communicating with the Kill Bill server: Object id=#{account_id} type=ACCOUNT doesn't exist!", flash[:error]
    end

    test 'should pay all invoices' do
      post :pay_all_invoices, params: { account_id: @account.account_id, is_external_payment: true }
      assert_response 302
    end

    test 'should trigger invoice' do
      account = create_account(@tenant)
      bundle = create_bundle(account, @tenant)

      parameters = {
        account_id: account.account_id,
        dry_run: '0'
      }

      post :trigger_invoice, params: parameters
      assert_equal 'Nothing to generate for target date today', flash[:notice]
      assert_redirected_to account_path(account.account_id)

      today_next_month = (Date.parse(@kb_clock['localDate']) + 31).to_s
      # generate a dry run invoice
      parameters = {
        account_id: account.account_id,
        dry_run: '1',
        target_date: today_next_month
      }

      post :trigger_invoice, params: parameters
      assert_response :success
      assert_select 'table tbody tr:first' do
        assert_select 'td:first', 'sports-monthly-evergreen'
        assert_select 'td:nth-child(4)', bundle.subscriptions.first.subscription_id
      end

      # persist it
      parameters[:dry_run] = '0'
      post :trigger_invoice, params: parameters
      assert_response :redirect
      assert_match(/Generated invoice.*for target date.*/, flash[:notice])
      a_tag = /<a.href="(?<href>.*?)">/.match(@response.body)
      assert_redirected_to a_tag[:href]
    end

    test 'should get next_invoice_date' do
      get :next_invoice_date, params: { account_id: @account.account_id }
      assert_not_nil @response.body
    end

    test 'should validate external key if found' do
      get :validate_external_key, params: { external_key: 'foo' }
      assert_response :success
      assert_equal JSON[@response.body]['is_found'], false

      external_key = SecureRandom.uuid.to_s
      post :create, params: { account: { external_key: } }
      assert_redirected_to account_path(redirected_account_id)

      get :validate_external_key, params: { external_key: }
      assert_response :success
      assert_equal JSON[@response.body]['is_found'], true
    end

    test 'should link and un-link to parent' do
      parent = create_account(@tenant)
      child = create_account(@tenant)

      # force an error linking a parent account
      child.parent_account_id = SecureRandom.uuid.to_s
      put :link_to_parent,
          params: {
            account: child.to_hash,
            account_id: child.account_id
          }
      assert_equal "Parent account id not found: #{child.parent_account_id}", flash[:error]
      assert_redirected_to account_path(child.account_id)

      # link parent account
      child.parent_account_id = parent.account_id
      put :link_to_parent,
          params: {
            account: child.to_hash,
            account_id: child.account_id
          }
      assert_equal 'Account successfully updated', flash[:notice]
      assert_redirected_to account_path(child.account_id)

      # un-link parent account
      delete :link_to_parent, params: { account_id: child.account_id }
      assert_equal 'Account successfully updated', flash[:notice]
      assert_redirected_to account_path(child.account_id)
    end

    test 'should set email notifications configuration if plugin is available' do
      parameters = {
        configuration: {
          account_id: @account.account_id,
          event_types: ['INVOICE_NOTIFICATION']
        }
      }

      post :set_email_notifications_configuration, params: parameters
      assert_equal(I18n.translate('errors.messages.email_notification_plugin_not_available'), flash[:error]) unless flash[:error].blank?
      assert_equal("Email notifications for account #{@account.account_id} was successfully updated", flash[:notice]) if flash[:error].blank?
      assert_redirected_to account_path(@account.account_id)
    end

    test 'should close an account' do
      account_to_be_closed = create_account(@tenant)

      delete :destroy, params: { account_id: account_to_be_closed.account_id }
      assert_redirected_to account_path(account_to_be_closed.account_id)
      assert_equal "Account #{account_to_be_closed.account_id} successfully closed", flash[:notice]
    end

    test 'should download a data' do
      account = create_account(@tenant)

      get :export_account, params: { account_id: account.account_id }
      assert_response :success
      assert_equal 'text/plain', @response.header['Content-Type']
    end

    test 'should download accounts data' do
      start_date = Date.today.strftime('%Y-%m-%d')
      end_date = Date.today.strftime('%Y-%m-%d')
      columns = %w[account_id name email bcd cba]
      account = create_account(@tenant)

      get :download, params: { startDate: start_date, endDate: end_date, allFieldsChecked: 'false', columnsString: columns.join(',') }
      assert_response :success
      assert_equal 'text/csv', @response.header['Content-Type']
      assert_includes @response.header['Content-Disposition'], "filename=\"accounts-#{Date.today}.csv\""
      assert_includes @response.body, account.account_id

      csv = CSV.parse(@response.body, headers: true)
      assert_equal %w[account_id name email bill_cycle_day_local account_cba], csv.headers
    end

    private

    def redirected_account_id
      fields = %r{<a.href="http:/.*/.*?/(?<id>.*?)">}.match(@response.body) if fields.nil?

      return nil if fields.nil?

      fields.nil? ? nil : fields[:id]
    end
  end
end
