# frozen_string_literal: true

module Teachers
  class FindOrCreateFromTeacherAuth
    def initialize(provider_data:, feature_flag_id:)
      @one_login_id = provider_data.uid
      @trn = provider_data.extra.raw_info.trn
      @email = provider_data.info.email
      @feature_flag_id = feature_flag_id
      @full_name = provider_data.extra.raw_info.verified_name.join(" ")
      @date_of_birth = Date.parse(provider_data.extra.raw_info.verified_date_of_birth, "%Y-%m-%d")
      @refresh_token = provider_data.credentials&.refresh_token
    end

    attr_reader :one_login_id, :trn, :email, :full_name, :date_of_birth, :feature_flag_id, :refresh_token

    def call
      teacher_matched_using_trn = matching_teachers.first

      if teacher_matched_using_trn
        merge_and_archive_clashing_email_teacher(teacher_matched_using_trn)
        teacher_matched_using_trn.update!(one_login_id:, provider: Omniauth::Strategies::TeacherAuth::NAME, email:, full_name:, feature_flag_id:)
        merge_and_archive_other_teachers(teacher_matched_using_trn, matching_teachers[1..])
        return teacher_matched_using_trn
      end

      teacher_matched_using_one_login_id = Teacher.find_by(provider: Omniauth::Strategies::TeacherAuth::NAME, one_login_id:)

      if teacher_matched_using_one_login_id
        merge_and_archive_clashing_email_teacher(teacher_matched_using_one_login_id)
        teacher_matched_using_one_login_id.update!(teacher_attributes)
        return teacher_matched_using_one_login_id
      end

      merge_and_archive_clashing_email_teacher(nil)
      create_teacher_with_provider_data
    end

  private

    def matching_teachers
      return [] if trn.blank?

      @matching_teachers ||= Teacher.where(trn:, archived_at: nil).order(updated_at: :desc).to_a
    end

    def merge_and_archive_other_teachers(teacher_to_keep, teachers_to_merge)
      teachers_to_merge.each do |teacher_to_merge|
        Teachers::MergeAndArchive.new(teacher_to_merge:, teacher_to_keep:).call(dry_run: false)
      end
    end

    def merge_and_archive_clashing_email_teacher(teacher_to_keep)
      clashing_teacher = Teacher.find_by(email:)
      return if clashing_teacher.nil? || clashing_teacher == teacher_to_keep

      if teacher_to_keep && clashing_teacher.trn.blank?
        Teachers::MergeAndArchive.new(teacher_to_merge: clashing_teacher, teacher_to_keep:).call(dry_run: false)
      else
        Teachers::Archiver.new(teacher: clashing_teacher).archive!
      end
    end

    def create_teacher_with_provider_data
      Teacher.create!(
        one_login_id:,
        provider: Omniauth::Strategies::TeacherAuth::NAME,
        date_of_birth:,
        **teacher_attributes,
      )
    end

    def teacher_attributes
      attrs = { email:, trn:, full_name:, feature_flag_id: }

      if trn.present?
        attrs.merge!(
          refresh_token: nil,
          refresh_token_updated_at: nil,
        )
      else
        attrs.merge!(
          refresh_token:,
          refresh_token_updated_at: Time.current,
        )
      end

      attrs
    end
  end
end
