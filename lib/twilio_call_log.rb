class TwilioCallLog
  def self.fetch_call_logs(start_time = nil)
    client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN

    query_condition = {status: "completed"}
    query_condition.merge!({start_time: start_time}) if start_time.present?

    User.all.each do |user|
      client.account.calls.list(query_condition.merge({to: "client:#{user.slug}"})).each do |call|
        unless CallLog.exists?(sid: call.sid)
          CallLog.create!(
            sid:        call.sid,
            user_id:    user.id,
            duration:   call.duration,
            start_time: call.start_time,
            end_time:   call.end_time,
            from:       call.from,
            to:         call.to,
            call_type:  CallLog::INCOMING
          )
        end
      end

      client.account.calls.list(query_condition.merge({from: "client:#{user.slug}"})).each do |call|
        unless CallLog.exists?(sid: call.sid)
          CallLog.create!(
            sid:        call.sid,
            user_id:    user.id,
            duration:   call.duration,
            start_time: call.start_time,
            end_time:   call.end_time,
            from:       call.from,
            to:         call.to,
            call_type:  CallLog::OUTGOING
          )
        end
      end

    end
  end
end
