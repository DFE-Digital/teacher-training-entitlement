class AdminUser < ApplicationRecord
  has_many :bulk_operations

  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }

  before_save :email_downcase, if: -> { email_changed? }

  def name_with_email
    "#{full_name} (#{email})"
  end

private

  def email_downcase
    email&.downcase!
  end
end
