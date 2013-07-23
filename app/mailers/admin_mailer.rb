class AdminMailer < ActionMailer::Base
  default from: "from@example.com"

  def new_user_waiting_for_approval(user)
    @user = user
    emails = User.admin.map(&:email).present? ? User.admin.map(&:email).join(",") : "tammam.kbeili@gmail.com"
    mail to: , subject: "new user waiting for approval: #{user.name}"
  end

end