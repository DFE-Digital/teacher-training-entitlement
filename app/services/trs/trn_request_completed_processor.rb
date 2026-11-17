module Trs
  class TrnRequestCompletedProcessor
    def initialize(webhook_message)
      @webhook_message = webhook_message
    end

    def call
      return webhook_message.mark_failed!("Message has no trnRequest.oneLoginUserSubject") if one_login_id.blank?
      return webhook_message.mark_failed!("Message has no trnRequest.trn") if trn.blank?
      return webhook_message.mark_failed!("No user found with this One Login ID") unless user

      ApplicationRecord.transaction do
        user.lock!
        user.update!(trn:, refresh_token: nil, refresh_token_updated_at: nil)
        merge_other_users_with_same_trn
        webhook_message.mark_processed!
      end
    end

  private

    attr_reader :webhook_message

    def user
      @user ||= User.find_by(provider: Omniauth::Strategies::TeacherAuth::NAME, one_login_id:)
    end

    def merge_other_users_with_same_trn
      User.where(trn:, archived_at: nil).where.not(id: user.id).find_each do |other_user|
        Users::MergeAndArchive.new(user_to_merge: other_user, user_to_keep: user).call(dry_run: false)
      end
    end

    def one_login_id
      trn_request["oneLoginUserSubject"]
    end

    def trn
      trn_request["trn"]
    end

    def trn_request
      webhook_message.message["trnRequest"] || {}
    end
  end
end
