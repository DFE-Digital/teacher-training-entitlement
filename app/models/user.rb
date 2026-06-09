class User < ApplicationRecord
  encrypts :refresh_token

  # TO DO: remove after succesful deploy
  self.ignored_columns += %w[get_an_identity_id_synced_to_ecf trn_verified trn_auto_verified]

  INSIGNIFICANT_ATTRIBUTES = %w[
    raw_tra_provider_data
    feature_flag_id
    updated_from_tra_at
    trn_lookup_status
    notify_user_for_future_reg
    email_updates_status
    email_updates_unsubscribe_key
    refresh_token
    refresh_token_updated_at
    trn_requested_at
  ].freeze

  devise :omniauthable, omniauth_providers: [Omniauth::Strategies::TeacherAuth::NAME]

  has_paper_trail meta: { note: :version_note }, ignore: %i[raw_tra_provider_data updated_at feature_flag_id refresh_token refresh_token_updated_at]

  has_many :applications, dependent: :destroy
  has_many :declarations, through: :applications
  has_many :participant_id_changes, -> { order("created_at desc") }
  has_many :declarations, through: :applications

  validates :full_name, presence: true

  validates :email,
            presence: true,
            uniqueness: true,
            notify_email: true

  validates :one_login_id, uniqueness: { allow_blank: true }
  validates :ecf_id, uniqueness: { case_sensitive: false }

  after_commit :touch_significantly_updated_at
  before_save :change_unsubscribe_key_on_update_email_status

  scope :admins, -> { where(admin: true) }
  scope :without_trn, -> { where(trn: nil).where.not(refresh_token: nil) }
  scope :requiring_token_refresh, lambda {
    without_trn
      .where("refresh_token_updated_at < ?", 1.day.ago)
      .where(trn_requested_at: nil)
  }
  scope :needing_trn_activation_check, -> { without_trn.where.not(trn_requested_at: nil) }

  EMAIL_UPDATES_STATES = [
    EMAIL_NPD_REGISTRATION_OPEN = :npd_registration_open,
  ].freeze

  enum :email_updates_status,
       { EMAIL_NPD_REGISTRATION_OPEN => EMAIL_NPD_REGISTRATION_OPEN.to_s },
       suffix: true

  attr_accessor :version_note, :skip_touch_significantly_updated_at

  def latest_participant_outcome(lead_provider, course_identifier)
    declarations.eligible_for_outcomes(lead_provider, course_identifier)
      .first
      &.participant_outcomes
      &.latest
  end

  def flipper_id
    "User;#{retrieve_or_persist_feature_flag_id}"
  end

  def retrieve_or_persist_feature_flag_id
    self.feature_flag_id ||= SecureRandom.uuid
    save!(validate: false) if feature_flag_id_changed?
    self.feature_flag_id
  end

  def archived?
    archived_email.present?
  end

  def set_closed_registration_feature_flag
    if Flipper.enabled?(Feature::CLOSED_REGISTRATION_ENABLED) && ClosedRegistrationUser.find_by(email:)
      Flipper.enable_actor(Feature::REGISTRATION_OPEN, self)
    end
  end

  def set_updated_from_tra_at
    return unless significant_change?

    self.updated_from_tra_at = Time.zone.now
  end

  def requires_token_refresh?
    trn.blank? && refresh_token.present? && trn_requested_at.blank?
  end

  def can_request_trn?
    trn.blank? && refresh_token.present?
  end

  def clear_auth_tokens!
    update!(refresh_token: nil, refresh_token_updated_at: nil)
  end

  def active_applications_for(course:, cohort:)
    applications
      .active_applications
      .joins(:course_cohort)
      .where(course_cohorts: { course_id: course.id, cohort_id: cohort.id })
  end

private

  def change_unsubscribe_key_on_update_email_status
    return unless email_updates_status_changed?

    self.email_updates_unsubscribe_key = if email_updates_status.blank?
                                           nil
                                         else
                                           SecureRandom.uuid
                                         end
  end

  def touch_significantly_updated_at
    return if skip_touch_significantly_updated_at

    changed_attributes = saved_changes.keys

    explicitly_updating_significantly_updated_at = changed_attributes.include?("significantly_updated_at")
    return if explicitly_updating_significantly_updated_at

    updated_at_touched = changed_attributes == %w[updated_at]

    update_column(:significantly_updated_at, updated_at) if updated_at_touched || significant_change?
  end

  def significant_change?
    (saved_changes.keys - (INSIGNIFICANT_ATTRIBUTES + %w[updated_at])).any? ||
      (changes.keys - (INSIGNIFICANT_ATTRIBUTES + %w[updated_at])).any?
  end
end
