require 'spec_helper'

describe KillBillClient::Model::Resource do
  class_var_name = '@@attribute_names'

  it 'should test has_one property' do
    #test account_timeline has one account
    #has_one :account, KillBillClient::Model::Account
    #expected "KillBillClient::Model::AccountTimeline"=>{:account=>{:type=>KillBillClient::Model::Account, :cardinality=>:one}, :payments=>{:type=>KillBillClient::Model::Payment, :cardinality=>:many}, :bundles=>{:type=>KillBillClient::Model::Bundle, :cardinality=>:many}, :invoices=>{:type=>KillBillClient::Model::Invoice, :cardinality=>:many}}
    test_var = KillBillClient::Model::AccountTimeline.class_variable_defined? class_var_name
    expect(test_var).not_to be(false)

    var = KillBillClient::Model::AccountTimeline.send(:class_variable_get, class_var_name)
    expect(var.size).to be > 0
    expect(var).to have_key "KillBillClient::Model::AccountTimeline"
    expect(var["KillBillClient::Model::AccountTimeline"]).to have_key :account

    attr = var["KillBillClient::Model::AccountTimeline"][:account]

    expect(attr).to have_key :type
    expect(attr).to have_key :cardinality

    expect(attr[:type]).to eq(KillBillClient::Model::Account)
    expect(attr[:cardinality]).to eq(:one) #has one

    #should also be accessible by attr_accessors

    methods = KillBillClient::Model::AccountTimeline.instance_methods
    expect(methods.map(&:to_sym)).to include :account     # attr_reader
    expect(methods.map(&:to_sym)).to include :account= #attr_writer
  end

  it 'should test has_many property' do
    #test event has many audit_logs
    #has_many :audit_logs, KillBillClient::Model::AuditLog
    #expected {"KillBillClient::Model::SubscriptionEvent"=>{:audit_logs=>{:type=>KillBillClient::Model::AuditLog, :cardinality=>:many}}}

    test_var = KillBillClient::Model::EventSubscription.class_variable_defined? class_var_name
    expect(test_var).to be(true)

    var = KillBillClient::Model::EventSubscription.send(:class_variable_get, class_var_name)
    expect(var.size).to be > 0
    expect(var).to have_key "KillBillClient::Model::Subscription"
    expect(var["KillBillClient::Model::Subscription"]).to have_key :events

    attr = var["KillBillClient::Model::Subscription"][:events]

    expect(attr).to have_key :type
    expect(attr).to have_key :cardinality

    expect(attr[:type]).to eq(KillBillClient::Model::EventSubscription)
    expect(attr[:cardinality]).to eq(:many) #has many

    #should also be accessible by attr_accessors

    methods = KillBillClient::Model::EventSubscription.instance_methods
    expect(methods.map(&:to_sym)).to include :audit_logs     # attr_reader
    expect(methods.map(&:to_sym)).to include :audit_logs= #attr_writer
  end

  it 'should create alias attr accessors' do
    KillBillClient::Model::EventSubscription.create_alias :alias_date, :effective_date

    methods = KillBillClient::Model::EventSubscription.instance_methods
    expect(methods.map(&:to_sym)).to include :alias_date
    expect(methods.map(&:to_sym)).to include :alias_date=

    evt = KillBillClient::Model::EventSubscription.new
    evt.alias_date = "devaroop"
    expect(evt.effective_date).to eq("devaroop")
    expect(evt.alias_date).to eq("devaroop")
  end
end

