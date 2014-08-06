require "net/https"

class PushOver
  def self.send_ping(user, from, device)
    url = URI.parse("https://api.pushover.net/1/messages.json")
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({
      token: "agZRm2NkAT5sFNHZWSsUxr9aQe9rbG",
      user: "ue7EQP6EXyFfiV3rpsYRqG1sgLCajH",
      message: "Incoming call from #{from}",
      title: "Incoming call",
      device: device.device_id,
      # add redirection url
      url: "http://my-med-labs-call-center.herokuapp.com/connects?user_email=#{user.email}&user_token=#{user.authentication_token}&from=#{from}"
    })
    res = Net::HTTP.new(url.host, url.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res.start {|http| http.request(req) }
  end
end
