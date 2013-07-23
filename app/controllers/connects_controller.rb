class ConnectsController < ApplicationController
  layout "connect"

  before_filter :check_logged_in_user, only: :index
  skip_before_filter :verify_authenticity_token

  CALLER_ID = "+14086457436"

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
    token = capability.generate
    render :index, locals: {token: token, client_name: @client_name}
  end

  def voice
    number = params[:PhoneNumber]

    response = Twilio::TwiML::Response.new do |r|
      # Should be your Twilio Number or a verified Caller ID
      r.Dial callerId: CALLER_ID do |d|
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

  def enqueue
    response = Twilio::TwiML::Response.new do |r|
      r.Enqueue action: '/voice', waitUrl: '/wait_url.xml', waitUrlMethod: 'GET' do |d|

      end
    end
    #FIXME: this is stupid but I can't figure out how to store nouns
    response_text = response.text
    response_text = response_text.gsub("</Enqueue>", "support</Enqueue>")

    render text: response_text
  end

  def about_to_connect
    response = Twilio::TwiML::Response.new do |r|
      r.Say "Thank you for waiting. An agent is about to connect with you now."
    end

  end

  def queue
    # response = Twilio::TwiML::Response.new do |r|
    #   r.Dial do |d|
    #     d.Queue action: '/about_to_connect.xml', method: 'GET'
    #   end
    # end

    # response_text = response.text
    # response_text = response_text.gsub("</Queue>", "support</Queue>")

    # render text: response_text

    account_sid = 'ACc9f94230884add84b3a5fa0d7c6df08a'
    auth_token = '827e6c207363a1b7b8f1c5861ecc8fe9'
    @client = Twilio::REST::Client.new account_sid, auth_token
    
    @client.account.queues.list.each do |queue|
      puts queue.send(:sid).inspect
      puts queue.sid.inspect
    end

    # Get an object from its sid. If you do not have a sid,
    # check out the list resource examples on this page
    @member = @client.account.queues.get(sid).members.get("Front")
    @member.update(url: "/voice.xml",
        method: "POST")
    puts @member.wait_time
  end

  def wait_url
    position = params[:QueuePosition]
    response = Twilio::TwiML::Response.new do |r|
      r.Say "You are caller number #{position}. Someone will be with you shortly."
      r.Play 'https://www.dropbox.com/s/z97h9xl4eu47v6d/banana.mp3?dl=1'
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
