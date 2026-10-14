class RenameTeacherRecordServiceScopeToWebhook < ActiveRecord::Migration[8.1]
  def change
    # safety_assured justification: the teacher_record_service scope has no
    # routed consumer on main (API::TeacherRecordService::V1::QualificationsController
    # is not wired into config/routes) and the webhook endpoints ship in this
    # branch, so no running code resolves the old value during deploy.
    # rename_enum_value rewrites the enum label in place, so any pre-created
    # token rows keep working under the new value.
    safety_assured { rename_enum_value :api_token_scopes, from: "teacher_record_service", to: "webhook" }
  end
end
