require "rails_helper"

RSpec.describe "merge_teacher_into_another" do
  let(:merge_and_archive_service) { service_double }
  let(:teacher_to_merge) { create(:teacher, :with_one_login_id) }
  let(:teacher_to_keep) { create(:teacher) }
  let(:service_double) { instance_double(Teachers::MergeAndArchive) }

  before { allow(Teachers::MergeAndArchive).to receive(:new).with(teacher_to_merge:, teacher_to_keep:, set_one_login_id: true, logger: Rails.logger) { merge_and_archive_service } }
  after { Rake::Task["merge_teacher_into_another"].reenable }

  subject(:run_task) { Rake::Task["merge_teacher_into_another"].invoke(teacher_to_merge.ecf_id, teacher_to_keep.ecf_id, dry_run) }

  it_behaves_like "passing dry_run to the service"

  context "when the teacher to merge does not exist" do
    subject(:run_task) { Rake::Task["merge_teacher_into_another"].invoke(SecureRandom.uuid, teacher_to_keep.ecf_id, "false") }

    it_behaves_like "exiting with error code 1"
  end

  context "when the teacher to keep does not exist" do
    subject(:run_task) { Rake::Task["merge_teacher_into_another"].invoke(teacher_to_merge.ecf_id, SecureRandom.uuid, "false") }

    it_behaves_like "exiting with error code 1"
  end
end
