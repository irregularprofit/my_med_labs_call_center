class ConnectsController < ApplicationController
  layout "connect"

  before_filter :check_logged_in_user, only: :index
  skip_before_filter :verify_authenticity_token

  def index
    @client_name = params[:client]
    @client_name = current_user.name if @client_name.nil?

    # Find these values at twilio.com/user/account
    account_sid = 'ACc9f94230884add84b3a5fa0d7c6df08a'
    auth_token = '827e6c207363a1b7b8f1c5861ecc8fe9'
    capability = Twilio::Util::Capability.new account_sid, auth_token
    # Create an application sid at twilio.com/user/account/apps and use it here
    capability.allow_client_outgoing "APeabd53438dea1a6b79f651bd14c9c875"
    capability.allow_client_incoming @client_name
    @token = capability.generate
    render :index, locals: {token: @token, client_name: @client_name}
  end

  def voice
    caller_id = "+14086457436"
    number = params[:PhoneNumber]

    response = Twilio::TwiML::Response.new do |r|
      # Should be your Twilio Number or a verified Caller ID
      r.Dial callerId: caller_id do |d|
        # Test to see if the PhoneNumber is a number, or a Client ID. In
        # this case, we detect a Client ID by the presence of non-numbers
        # in the PhoneNumber parameter.
        if number.nil?
          #FIXME: Why can't I access current user
          d.Client User.first.name
        elsif /^[\d\+\-\(\) ]+$/.match(number)
          d.Number(CGI::escapeHTML number)
        else
          d.Client number
        end
      end
    end

    render text: response.text
  end

  private

  def check_logged_in_user
    unless current_user.present?
      redirect_to new_user_session_url, notice: "Please login first"
    end
  end

end
