class User < ActiveRecord::Base
  acts_as_token_authenticatable

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  after_create :send_admin_mail
  after_create :underscore_paramaterize_slug

  has_many :call_logs
  has_many :devices
  has_one :schedule

  scope :active,    -> {where(approved: true)}
  scope :admin,     -> {where(is_admin: true)}
  scope :non_admin, -> {where(is_admin: false)}
  scope :inactive,  -> {where(approved: false)}

  extend FriendlyId
  friendly_id :name, use: :slugged, sequence_separator: "_"

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if !recoverable.approved?
      recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end

  def on_call?
    return true # always on for testing

    schedule = self.schedule
    # user is not on call if there is no schedule, or if schedule is disabled
    return false if schedule.nil? || !schedule.enabled?

    time = Time.now

    # current time is greater than schedule start time and less than schedule off time
    time.wday > schedule.start_day &&
      time.wday < schedule.end_day &&
      time.hour > schedule.start_hour &&
      time.hour < schedule.end_hour &&
      time.min > schedule.start_min &&
      time.min < schedule.end_min
  end

  def get_capability_token
    capability = Twilio::Util::Capability.new ACCOUNT_SID, AUTH_TOKEN

    # Create an application sid at twilio.com/user/account/apps and use it here
    capability.allow_client_outgoing APP_TOKEN
    capability.allow_client_incoming self.slug
    capability.generate
  end

  private

  def underscore_paramaterize_slug
    self.slug = self.slug.underscore
    self.save
  end

  def send_admin_mail
    AdminMailer.new_user_waiting_for_approval(self).deliver
  end

end
