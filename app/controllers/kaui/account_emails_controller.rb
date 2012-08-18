module Kaui
  class AccountEmailsController < ApplicationController
    # GET /account_emails/1
    # GET /account_emails/1.json
    def show
      @account_id = params[:id]
      @account_emails = AccountEmail.where(:account_id => @account_id)

      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @account_email }
      end
    end

    # GET /account_emails/new
    # GET /account_emails/new.json
    def new
      @account_email = AccountEmail.new(:account_id => params[:account_id])

      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @account_email }
      end
    end

    # POST /account_emails
    # POST /account_emails.json
    def create
      @account_email = AccountEmail.new(params[:account_email])

      respond_to do |format|
        if @account_email.save
          format.html { redirect_to account_email_path(@account_email), :notice => 'Account email was successfully created.' }
          format.json { render :json => @account_email, :status => :created, :location => @account_email }
        else
          format.html { render :action => "new" }
          format.json { render :json => @account_email.errors, :status => :unprocessable_entity }
        end
      end
    end

    # DELETE /account_emails/1
    # DELETE /account_emails/1.json
    def destroy
      @account_email = AccountEmail.where(:account_id => params[:id], :email => params[:email])
      @account_email.destroy

      respond_to do |format|
        format.html { redirect_to account_email_path(params[:id]) }
        format.json { head :no_content }
      end
    end
  end
end
