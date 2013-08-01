class ConnectsController < ApplicationController
  layout "connect"

  before_filter :check_logged_in_user, only: :index
  skip_before_filter :verify_authenticity_token

  #real
  CALLER_ID = "+14086457436"
  ACCOUNT_SID = 'ACc9f94230884add84b3a5fa0d7c6df08a'
  AUTH_TOKEN = '827e6c207363a1b7b8f1c5861ecc8fe9'

  def index
    capability = Twilio::Util::Capability.new ACCOUNT_SID, AUTH_TOKEN
    # Create an application sid at twilio.com/user/account/apps and use it here
    capability.allow_client_outgoing "APeabd53438dea1a6b79f651bd14c9c875"
    capability.allow_client_incoming current_user.name
    token = capability.generate
    render :index, locals: {token: token, client_name: current_user.name}
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
      r.Enqueue waitUrl: '/wait_url.xml', waitUrlMethod: 'GET' do |d|

      end
    end
    #FIXME: this is stupid but I can't figure out how to store nouns
    response_text = response.text
    response_text = response_text.gsub("</Enqueue>", "support</Enqueue>")

    render text: response_text
  end

  def wait_url
    position = params[:QueuePosition]
    response = Twilio::TwiML::Response.new do |r|
      r.Say "You are caller number #{position}. Someone will be with you shortly."
      r.Play 'https://www.dropbox.com/s/z97h9xl4eu47v6d/banana.mp3?dl=1'
    end

    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    User.all.each do |user|
      @client.account.calls.create(
        url: "http://my-med-labs-call-center.herokuapp.com/queue?agent=#{user.name}",
        to: "client:#{user.name}",
        from: "client:#{user.name}"
      )
    end

    render text: response.text
  end

  def queue
    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Queue do |q|

        end
      end
    end

    #FIXME: this is stupid but I can't figure out how to store nouns
    response_text = response.text
    response_text = response_text.gsub("</Queue>", "support</Queue>")

    render text: response_text
  end

  def init_conference
    invited_agent = params[:agent]
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    call = @client.account.calls.create(
      url: "http://my-med-labs-call-center.herokuapp.com/conference",
      to: "client:#{invited_agent}",
      from: "client:#{current_user.name}"
    )
    call = @client.account.calls.create(
      url: "http://my-med-labs-call-center.herokuapp.com/conference",
      to: "client:#{current_user.name}",
      from: "client:#{current_user.name}"
    )
  end

  def conference
    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Conference beep: false, waitUrl: '', startConferenceOnEnter: true, endConferenceOnExit: true do |d|

        end
      end
    end

    #FIXME: this is stupid but I can't figure out how to store nouns
    response_text = response.text
    response_text = response_text.gsub("</Conference>", "simple_conference_room</Conference>")

    render text: response_text
  end

  def check_rooms
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    @client.account.conferences.list({
      status: "in-progress"}).each do |conference|

      puts conference.sid.inspect.red
      puts conference.status.inspect.red
      puts conference.friendly_name.inspect.red
    end

    @client.account.conferences.list({
      status: "init"}).each do |conference|

      puts conference.sid.inspect.blue
      puts conference.status.inspect.blue
      puts conference.friendly_name.inspect.blue
    end

    conference_sid = @client.account.conferences.list({status: "in-progress"}).first.sid
    @client.account.conferences.get(conference_sid).participants.list.each do |participant|
      puts participant.inspect.blue
    end

  end

  private

  def check_logged_in_user
    unless current_user.present?
      redirect_to new_user_session_url, notice: "Please login first"
    end
  end

end
