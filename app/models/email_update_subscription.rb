class EmailUpdateSubscription < ApplicationRecord
  has_secure_token :unsubscribe_key

  STATUSES = [
    NPD_REGISTRATION_OPEN = "npd_registration_open".freeze,
  ].freeze

  enum :status, STATUSES.index_with(&:itself), suffix: true

  validates :email, presence: true, notify_email: true, uniqueness: { scope: :status }
  validates :status, presence: true
end
