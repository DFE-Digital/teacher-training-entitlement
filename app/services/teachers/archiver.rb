# frozen_string_literal: true

module Teachers
  class Archiver
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :teacher

    def archive!
      raise ArgumentError, "Teacher already archived" if teacher.archived?

      teacher.archived_email = teacher.email
      teacher.archived_at = Time.zone.now
      teacher.email = "archived-#{teacher.email}"
      teacher.one_login_id = nil
      teacher.provider = nil
      teacher.save!
    end

    def set_one_login_id_to_nil!
      teacher.update!(one_login_id: nil)
    end
  end
end
