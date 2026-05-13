# frozen_string_literal: true

module Users
  class FindOrCreateFromTeacherAuth
    def initialize(provider_data:, feature_flag_id:)
      @one_login_id = provider_data.uid
      @trn = provider_data.extra.raw_info.trn
      @email = provider_data.info.email
      @feature_flag_id = feature_flag_id
      @full_name = provider_data.extra.raw_info.verified_name.join(" ")
      @date_of_birth = Date.parse(provider_data.extra.raw_info.verified_date_of_birth, "%Y-%m-%d")
    end

    attr_reader :one_login_id, :trn, :email, :full_name, :date_of_birth, :feature_flag_id

    def call
      user_matched_using_trn = matching_users.first

      if user_matched_using_trn
        user_matched_using_trn.update!(one_login_id:, provider: Omniauth::Strategies::TeacherAuth::NAME, email:, full_name:, feature_flag_id:)
        merge_and_archive_other_users(user_matched_using_trn, matching_users[1..])
        return user_matched_using_trn
      end

      user_matched_using_one_login_id = User.find_by(provider: Omniauth::Strategies::TeacherAuth::NAME, one_login_id:)

      if user_matched_using_one_login_id
        user_matched_using_one_login_id.update!(email:, trn:, trn_verified: true, trn_auto_verified: true, full_name:, feature_flag_id:)
        return user_matched_using_one_login_id
      end

      create_user_with_provider_data
    end

  private

    def matching_users
      return [] if trn.blank?

      @matching_users ||= User.where(trn:, trn_verified: true, archived_at: nil).order(updated_at: :desc).to_a
    end

    def merge_and_archive_other_users(user_to_keep, users_to_merge)
      users_to_merge.each do |user_to_merge|
        Users::MergeAndArchive.new(user_to_merge:, user_to_keep:).call(dry_run: false)
      end
    end

    def create_user_with_provider_data
      User.create!(
        one_login_id:,
        provider: Omniauth::Strategies::TeacherAuth::NAME,
        email:,
        trn:,
        trn_verified: true,
        trn_auto_verified: true,
        full_name:,
        date_of_birth:,
        feature_flag_id:,
      )
    end
  end
end
