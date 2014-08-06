require "net/https"

class PushOver

  def initialize(options = {})
    @user = options[:user]
    @from = options[:from]
  end

  def prepare_call
    if still_ringing?
      # dial all on_call users
      User.all.each do |agent|
        if agent.on_call? && agent.devices.first
          send_ping(agent, agent.devices.first)
        end
      end
    end
  end

  def dial_user
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    if still_ringing?
      @client.account.calls.create(
        url: "http://my-med-labs-call-center.herokuapp.com/queue?user_email=#{@user.email}&user_token=#{@user.authentication_token}",
        from: @from,
        to: "client:#{@user.slug}"
      )
    end
  end

  def still_ringing?
    @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    @client.account.calls.list({
      status: "in-progress",
      from: @from,
      to: CALLER_ID,
      direction: "inbound"}).present?
  end

  def send_ping(agent, device)
    url = URI.parse("https://api.pushover.net/1/messages.json")
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({
      token: API_TOKEN,
      user: USER_KEY,
      message: "Incoming call from #{@from}",
      title: "Incoming call",
      device: device.device_id,
      # add redirection url
      url: "http://my-med-labs-call-center.herokuapp.com/connects?user_email=#{agent.email}&user_token=#{agent.authentication_token}&from=#{@from}"
    })
    res = Net::HTTP.new(url.host, url.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res.start {|http| http.request(req) }
  end

  handle_asynchronously :prepare_call, run_at: Proc.new { 8.seconds.from_now }
  handle_asynchronously :dial_user, run_at: Proc.new { 5.seconds.from_now }

end
