xml.instruct!
xml.Response do
    xml.Dial do
        xml.Conference(@room, waitUrl: '', startConferenceOnEnter: true, endConferenceOnExit: true)
    end
    xml.Say "Waiting in conference room"
end
