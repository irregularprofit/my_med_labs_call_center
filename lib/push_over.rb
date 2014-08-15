require "net/https"

class PushOver

  def initialize()
  end

  # system received call, notifying all users
  #  from is always just number
  def notify_all_agents_of_call(from)
    if still_ringing?(from)
      # dial all on_call users
      User.all.each do |agent|
        if agent.on_call?
          dial_user(from, agent, {send_ping: true})
        end
      end
    end
  end

  # call to user from twilio and push_over
  #  from is string (could be number or twilio client slug)
  #  agent is always a user object, recipient of the call
  #  options hash
  #    send_ping - whether to send notification through push over
  #    room - specify the conference room the user will be redirected to
  def dial_user(from, agent, options = {})
    send_ping = options.delete(:send_ping)
    room = options.delete(:room)
    action = options.delete(:action) || 'queue'
    skip_ping_check = options.delete(:skip_ping_check)
    single_dir = options.delete(:single_dir)

    client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    unless from =~ /\d/
      from = "client:#{from}"
    end

    if skip_ping_check || still_ringing?(from)
      # compose the url to send request to
      url = "http://my-med-labs-call-center.herokuapp.com/#{action}"
      url_params = "?user_email=#{agent.email}&user_token=#{agent.authentication_token}"
      url_params = "#{url_params}&from=#{from}" if from

      if room
        url_params = "#{url_params}&room=#{room}"
        if single_dir
          url_params = "#{url_params}&conf_response=true"
        end
      end

      puts "new sending request - #{url}#{url_params}".inspect

      # dial twilio agent
      client.account.calls.create(
        url: "#{url}#{url_params}",
        from: from,
        to: "client:#{agent.slug}"
      )

      # send notification to device if it's known
      if send_ping && agent.devices.first
        send_push_notification(from, agent, agent.devices.first, "http://my-med-labs-call-center.herokuapp.com/connects#{url_params}")
      end
    end
  end

  # send invite from FROM to TO for conference
  #  from is the twilio client id
  #  to is the twilio client id
  def invite_to_conference(from, to, single_dir, room = nil)
    puts "send invite from: #{from} to: #{to} for room: #{room}, will #{single_dir ? 'not dial' : 'dial'} in response".red_on_yellow
    agent = User.find_by_slug(to)

    dial_user(from, agent, {room: room, action: 'conference', send_ping: true, skip_ping_check: true, single_dir: single_dir})
  end

  def send_push_notification(from, agent, device, url)
    message_json = URI.parse("https://api.pushover.net/1/messages.json")
    req = Net::HTTP::Post.new(message_json.path)
    req.set_form_data({
      token: API_TOKEN,
      user: USER_KEY,
      message: "Incoming call from #{from}",
      title: "Incoming call",
      device: device.device_id,
      # add redirection url
      url: url
    })
    res = Net::HTTP.new(message_json.host, message_json.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res.start {|http| http.request(req) }
  end

  # check if caller phone is still ringing
  def still_ringing?(from)
    client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    client.account.calls.list({
      status: "in-progress",
      from: from,
      to: CALLER_ID,
      direction: "inbound"}).present?
  end

  # check if a conference by name is already started
  def conference_in_progress?(room)
    client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    client.account.conferences.list({
      status: "in-progress",
      friendly_name: room}).each do |conf|
      puts "conference #{conf.friendly_name} is in #{conf.status}"
    end

    client.account.conferences.list({
      status: "in-progress",
      friendly_name: room}).present?
  end

  handle_asynchronously :notify_all_agents_of_call, run_at: Proc.new { 4.seconds.from_now }
  handle_asynchronously :dial_user, run_at: Proc.new { 2.seconds.from_now }
  handle_asynchronously :invite_to_conference

end
