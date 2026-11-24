# Moves all applications and declarations from one teacher to another teacher, then archives the first teacher
# If both teachers have a one_login_id, then the one_login_id of the teacher being kept is used
# usage:
# rake 'merge_teacher_into_another[<teacher_to_merge_and_archive>,<teacher_to_keep>,<dry_run>]'
# e.g.
# for dry run: rake 'merge_teacher_into_another[d43d7f28-aa93-45b9-b641-dd7dfd63516e,542657a1-28a4-4d7d-bb1b-0beb8ca3abe2]'
# for real run: rake 'merge_teacher_into_another[d43d7f28-aa93-45b9-b641-dd7dfd63516e,542657a1-28a4-4d7d-bb1b-0beb8ca3abe2,false]'
desc "Merge a teacher into another teacher"
task :merge_teacher_into_another, %i[teacher_ecf_id_to_merge teacher_ecf_id_to_keep dry_run] => :versioned_environment do |_task, args|
  logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
  dry_run = args[:dry_run] != "false"

  teacher_to_merge = Teacher.find_by(ecf_id: args[:teacher_ecf_id_to_merge])
  unless teacher_to_merge
    logger.error "Teacher to merge not found (ID: #{args[:teacher_ecf_id_to_merge]})"
    exit 1
  end

  teacher_to_keep = Teacher.find_by(ecf_id: args[:teacher_ecf_id_to_keep])
  unless teacher_to_keep
    logger.error "Teacher to keep not found (ID: #{args[:teacher_ecf_id_to_keep]})"
    exit 1
  end

  Teachers::MergeAndArchive.new(teacher_to_merge:, teacher_to_keep:, set_one_login_id: true, logger:).call(dry_run:)
end
