# frozen_string_literal: true

module Teachers
  class MergeAndArchive
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :teacher_to_merge
    attribute :teacher_to_keep
    attribute :set_one_login_id, :boolean, default: false
    attribute :logger, default: -> { Rails.logger }
    private :teacher_to_merge, :teacher_to_keep, :set_one_login_id

    def call(dry_run: true)
      logger.info "Dry Run" if dry_run

      ApplicationRecord.transaction do
        move_applications(from_teacher: teacher_to_merge, to_teacher: teacher_to_keep)
        move_participant_id_changes(from_teacher: teacher_to_merge, to_teacher: teacher_to_keep)
        teacher_to_keep.participant_id_changes.find_or_create_by!(from_participant_id: teacher_to_merge.ecf_id, to_participant_id: teacher_to_keep.ecf_id)
        one_login_id_to_keep = teacher_to_merge.one_login_id if teacher_to_merge.one_login_id.present? && teacher_to_keep.one_login_id.blank?

        logger.info("Archiving teacher ID=#{teacher_to_merge.id}")
        Teachers::Archiver.new(teacher: teacher_to_merge.reload).archive!

        if one_login_id_to_keep && set_one_login_id
          logger.info("Setting one_login_id=#{one_login_id_to_keep} on teacher ID=#{teacher_to_keep.id}")
          teacher_to_keep.update!(one_login_id: one_login_id_to_keep)
        end

        raise ActiveRecord::Rollback if dry_run
      end
    end

  private

    def move_applications(from_teacher:, to_teacher:)
      from_teacher.applications.each do |application|
        logger.info("Moving application ID=#{application.id} from teacher ID=#{from_teacher.id} to teacher ID=#{to_teacher.id}")
        application.update!(teacher: to_teacher)
      end
    end

    def move_participant_id_changes(from_teacher:, to_teacher:)
      if from_teacher.participant_id_changes.any?
        logger.info("Moving participant ID changes IDs=#{from_teacher.participant_id_changes.pluck(:id)} from teacher ID=#{from_teacher.id} to teacher ID=#{to_teacher.id}")
        from_teacher.participant_id_changes.update!(teacher: to_teacher)
      end
    end
  end
end
