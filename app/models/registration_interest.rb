class RegistrationInterest < ApplicationRecord
  validates :email,
            presence: true,
            length: { maximum: 128 },
            uniqueness: { case_sensitive: false },
            notify_email: true

  scope :not_yet_notified, -> { where(notified: false) }
end
