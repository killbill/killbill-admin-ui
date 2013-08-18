class Kaui::EngineController < ApplicationController
  before_filter :authenticate_user!

  layout :get_layout

  # Common options for the Kill Bill client
  def options_for_klient(options = {})
    {
      :api_key => KillBillClient.api_key,
      :api_secret => KillBillClient.api_secret,
      :username => current_user.kb_username || KillBillClient.username,
      :password => current_user.password || KillBillClient.password
    }.merge(options)
  end

  # Used for auditing purposes
  def current_user
    super rescue Kaui.config[:default_current_user]
  end

  def current_ability
    # Redefined here to namespace Ability in the correct module
    @current_ability ||= Kaui::Ability.new(current_user)
  end

  protected

  def as_string(e)
    if e.is_a?(RestClient::Exception)
      "#{e.message}, server response: #{as_string_from_response(e.response)}".split(/\n/).take(5).join("\n")
    elsif e.is_a?(KillBillClient::API::ResponseError)
      "Error #{e.response.code}: #{as_string_from_response(e.response.body)}"
    else
      e.message
    end
  end

  def as_string_from_response(response)
    error_message = response
    begin
      # BillingExceptionJson?
      error_message = JSON.parse response
    rescue => e
    end

    if error_message.respond_to? :[] and error_message['message'].present?
      # Likely BillingExceptionJson
      error_message = error_message['message']
    end
    # Limit the error size to avoid ActionDispatch::Cookies::CookieOverflow
    error_message[0..1000]
  end

  def get_layout
    layout ||= Kaui.config[:layout]
  end
end
