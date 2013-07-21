class AdminMailer < ActionMailer::Base
  default from: "from@example.com"

  def new_user_waiting_for_approval(user)
    @user = user
    mail to: User.admin.map(&:email).join(","), subject: "new user waiting for approval: #{user.name}"
  end

end