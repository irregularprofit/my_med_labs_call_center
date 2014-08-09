class ConnectsController < ApplicationController
  layout "connect"

  acts_as_token_authentication_handler_for User, only: [:index, :queue, :conference]
  before_filter :print_stuff
  skip_before_filter :verify_authenticity_token

  def index
    capability = Twilio::Util::Capability.new ACCOUNT_SID, AUTH_TOKEN

    # Create an application sid at twilio.com/user/account/apps and use it here
    capability.allow_client_outgoing APP_TOKEN
    capability.allow_client_incoming current_user.slug
    token = capability.generate

    if params[:from]
      number = params[:from].dup
      number = number.strip
      number = "+#{number}" unless number.start_with?("+")

      push_over = PushOver.new({user: current_user, from: number})
      push_over.dial_user()
    end

    render :index, locals: {token: token}
  end

  def enqueue
    number = params[:PhoneNumber]

    # dialing a number
    if number
      number = "+#{number}" unless number.start_with?("+")
      response = Twilio::TwiML::Response.new do |r|
        r.Dial callerId: CALLER_ID do |d|
          d.Number(number)
        end
      end

      response_text = response.text
      # receive call, put caller on queue
    else
      response = Twilio::TwiML::Response.new do |r|
        r.Enqueue waitUrl: '/wait_url.xml', waitUrlMethod: 'GET' do |d|

        end
      end
      #FIXME: this is stupid but I can't figure out how to store nouns
      response_text = response.text
      response_text = response_text.gsub("</Enqueue>", "support</Enqueue>")
    end

    render text: response_text
  end

  def wait_url
    position = params[:QueuePosition]
    response = Twilio::TwiML::Response.new do |r|
      r.Say "You are caller number #{position}. Someone will be with you shortly."
      r.Play 'https://www.dropbox.com/s/z97h9xl4eu47v6d/banana.mp3?dl=1'
    end

    push_over = PushOver.new({from: params[:From]})
    push_over.prepare_call()

    render text: response.text
  end

  def queue
    agent_id = params[:agent_id] || current_user.id

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

      # kill outgoing connections from caller to any other agent on the line
      User.where("id != ?", agent_id).all.each do |user|
        ringing_call = @client.account.calls.list({
                                                    status: "ringing",
                                                    from: params[:Caller],
                                                    to: "client:#{user.slug}"
        }).first
        if ringing_call
          ringing_call.update(status: "completed")
        end
      end

      # kill other outgoing connections to current user after user has picked up a call
      agent = User.find(agent_id)
      @client.account.calls.list({status: "ringing", to: "client:#{agent.slug}"}).each do |call|
        call.update(status: "completed")
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
    agent = User.find_by_slug(invited_agent)

    push_over = PushOver.new()
    push_over.invite_to_conference(invited_agent, current_user.slug)

    if number.present?
      @client.account.calls.list({status: "in-progress"}).each do |call|
        puts "Call #{call.status} from #{call.from} to #{call.to} as #{call.direction} starting at #{call.start_time} and ending at #{call.end_time} lasting #{call.duration}".red
      end

      @client.account.calls.list({
                                   from: number,
                                   to: CALLER_ID,
                                   status: "in-progress"
      }).each do |call|
        puts "Call #{call.status} from #{call.from} to #{call.to} as #{call.direction} starting at #{call.start_time} and ending at #{call.end_time} lasting #{call.duration}".blue
        puts "Redirect call now".blue
        call.update(
          url: "http://my-med-labs-call-center.herokuapp.com/conference?org=client:#{current_user.slug}&dest=client:#{invited_agent}",
          method: "POST"
        )
      end

      call = @client.account.calls.create(
        url: "http://my-med-labs-call-center.herokuapp.com/conference?org=client:#{current_user.slug}&dest=client:#{invited_agent}",
        from: "client:#{invited_agent}",
        to: "client:#{current_user.slug}"
      )
    end

    render nothing: true
  end

  def conference
    from = params[:org] || params[:From]
    to = params[:dest] || params[:To]

    from = from.gsub("client:", "")
    to = to.gsub("client:", "")

    room = params[:room] || "#{from}_c_#{to}"

    response = Twilio::TwiML::Response.new do |r|
      r.Dial do |d|
        d.Conference waitUrl: '', startConferenceOnEnter: true, endConferenceOnExit: true do |d|

        end
      end
    end

    push_over = PushOver.new()
    push_over.invite_to_conference(from, to, room)

    #FIXME: this is stupid but I can't figure out how to store nouns
    response_text = response.text
    response_text = response_text.gsub("</Conference>", "#{room}</Conference>")

    puts '*****************'
    puts response_text.inspect
    puts "to #{to.inspect}"
    puts "from #{from.inspect}"
    puts "room #{room}"
    puts '*****************'

    render text: response_text
  end

  def check_logs
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN
    @client.account.calls.list({
                                 :"start_time>" => Date.today.to_s,
                                 :"start_time<" => Date.tomorrow.to_s,
                                 to: "client:#{current_user.slug}"
    }).each do |call|
      puts "Call #{call.status} from #{call.from} to #{call.to} starting at #{call.start_time} and ending at #{call.end_time} lasting #{call.duration}".red_on_yellow
    end

    render nothing: true
  end

  def check_rooms
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    @client.account.conferences.list({status: "in-progress"}).each do |conference|
      puts "Conference #{conference.status} named #{conference.friendly_name}:#{conference.sid}".blue
      conference.participants.list.each do |participant|
        puts "Conference #{conference.status} named #{conference.friendly_name}:#{conference.sid} with participant #{participant.call_sid}".red
      end
    end

    @client.account.conferences.list({status: "init"}).each do |conference|
      puts "Conference #{conference.status} named #{conference.friendly_name}:#{conference.sid}".blue
      conference.participants.list.each do |participant|
        puts "Conference #{conference.status} named #{conference.friendly_name}:#{conference.sid} with participant #{participant.call_sid}".red
      end
    end

    render nothing: true
  end

  private

  def print_stuff
    puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    puts "action #{params[:action].inspect}"
    puts "current_user #{current_user.inspect}"
    puts "user_signed_in #{user_signed_in?.inspect}"
    puts "params #{params.inspect}"
    puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
  end

  def check_logged_in_user
    unless current_user.present?
      redirect_to new_user_session_url, notice: "Please login first"
    end
  end

end
