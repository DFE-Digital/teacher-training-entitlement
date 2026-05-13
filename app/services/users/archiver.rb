# frozen_string_literal: true

module Users
  class Archiver
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user

    def archive!
      raise ArgumentError, "User already archived" if user.archived?

      user.archived_email = user.email
      user.archived_at = Time.zone.now
      user.email = "archived-#{user.email}"
      user.one_login_id = nil
      user.provider = nil
      user.save!
    end

    def set_one_login_id_to_nil!
      user.update!(one_login_id: nil)
    end
  end
end
