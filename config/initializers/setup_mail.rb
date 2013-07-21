ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "gmail.com",
  :user_name            => "answerawesome",
  :password             => "Sup3r$ecret",
  :authentication       => "plain",
  :enable_starttls_auto => true
}