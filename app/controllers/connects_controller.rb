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
        url: "http://my-med-labs-call-center.herokuapp.com/queue?agent_id=#{user.id}",
        from: params[:From],
        to: "client:#{user.name}"
      )
    end

    render text: response.text
  end

  def queue
    agent_id = params[:agent_id]
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    if @client.account.queues.list.first.current_size == 0
      response = Twilio::TwiML::Response.new do |r|
        r.Say "The user call in queue has already been picked up."
        r.Reject
      end

      response_text = response.text
    else
      response = Twilio::TwiML::Response.new do |r|
        r.Dial do |d|
          d.Queue url: "about_to_connect.xml" do |q|

          end
        end
      end

      User.where("id != ?", agent_id).all.each do |user|
        ringing_call = @client.account.calls.list({
                                                    status: "ringing",
                                                    from: params[:Caller],
                                                    to: "client:#{user.name}"
        }).first
        if ringing_call
          ringing_call.update(status: "completed")
        end
      end

      #FIXME: this is stupid but I can't figure out how to store nouns
      response_text = response.text
      response_text = response_text.gsub("</Queue>", "support</Queue>")
    end

    render text: response_text
  end

  def about_to_connect
    response = Twilio::TwiML::Response.new do |r|
      r.Say "Thank you for your patience. An agent is on line and will be connecting to your call now."
    end

    render text: response.text
  end

  def init_conference
    invited_agent = params[:agent]
    number = params[:from]

    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    call = @client.account.calls.create(
      url: "http://my-med-labs-call-center.herokuapp.com/conference",
      from: "client:#{current_user.name}",
      to: "client:#{invited_agent}"
    )

    if number.present?
      @client.account.calls.list({
                                   status: "in-progress"
      }).each do |current_call|
        puts current_call.sid.red
        puts current_call.from.red
        puts current_call.to.red
        puts current_call.direction.red
      end

      @client.account.calls.list({
                                   from: number,
                                   to: CALLER_ID,
                                   status: "in-progress"
      }).each do |current_call|
        current_call.update(
          url: "http://my-med-labs-call-center.herokuapp.com/conference?org=client:#{current_user.name}&dest=client:#{invited_agent}",
          method: "POST"
        )
      end

      call = @client.account.calls.create(
        url: "http://my-med-labs-call-center.herokuapp.com/conference?org=client:#{current_user.name}&dest=client:#{invited_agent}",
        from: "client:#{invited_agent}",
        to: "client:#{current_user.name}"
      )
    end

    render nothing: true
  end

  def conference
    from_agent = params[:org] || params[:From]
    to_agent = params[:dest] || params[:To]

    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Conference waitUrl: '', startConferenceOnEnter: true, endConferenceOnExit: true do |d|

        end
      end
    end

    #FIXME: this is stupid but I can't figure out how to store nouns
    response_text = response.text
    response_text = response_text.gsub("</Conference>", "#{from_agent}_conference_#{to_agent}</Conference>")

    render text: response_text
  end

  def check_logs
    puts "completed".blue
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN
    @client.account.calls.list({
                                 to: "client:#{current_user.name}",
                                 status: "completed",
                                 :"start_time>" => Date.today.to_s,
                                 :"start_time<" => Date.tomorrow.to_s
    }).each do |call|
      puts '-'*100
      puts call.start_time
      puts call.end_time
      puts call.duration
    end

    puts "in-progress".red
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN
    @client.account.calls.list({
                                 :"start_time>" => Date.today.to_s,
                                 :"start_time<" => Date.tomorrow.to_s
    }).each do |call|
      puts '-'*100
      puts call.from
      puts call.to
      puts call.start_time
      puts call.end_time
      puts call.duration
      puts call.status
    end

    render nothing: true
  end

  def check_rooms
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    @client.account.conferences.list({
                                       status: "in-progress"
    }).each do |conference|

      puts conference.sid.inspect.red
      puts conference.status.inspect.red
      puts conference.friendly_name.inspect.red
    end

    @client.account.conferences.list({
                                       status: "init"
    }).each do |conference|

      puts conference.sid.inspect.blue
      puts conference.status.inspect.blue
      puts conference.friendly_name.inspect.blue
    end

    conference_room = @client.account.conferences.list({
                                                         status: "in-progress"
    }).first

    if conference_room.present?
      @client.account.conferences.get(conference_room.sid).participants.list.each do |participant|
        puts participant.call_sid.blue
        puts participant.conference_sid.blue
        puts participant.start_conference_on_enter.inspect.blue
        puts participant.end_conference_on_exit.inspect.blue
        puts participant.uri.blue
        puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'.blue
      end
    end
    render nothing: true
  end

  private

  def check_logged_in_user
    unless current_user.present?
      redirect_to new_user_session_url, notice: "Please login first"
    end
  end

end
