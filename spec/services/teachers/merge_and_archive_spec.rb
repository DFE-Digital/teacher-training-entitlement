require "rails_helper"

RSpec.describe Teachers::MergeAndArchive do
  let(:teacher_to_merge) { create(:teacher, :with_one_login_id) }
  let(:teacher_to_keep) { create(:teacher) }
  let(:course) { create(Course::IDENTIFIERS.first.to_sym) }

  let!(:teacher_to_keep_rejected_application) { create(:application, :rejected, :for_cohort_starting_on, teacher: teacher_to_keep, course:, registration_starts_at: Date.new(2021, 4, 1)) }
  let!(:teacher_to_keep_pending_application) { create(:application, :pending, :for_cohort_starting_on, teacher: teacher_to_keep, course:, registration_starts_at: Date.new(2021, 5, 1)) }
  let!(:teacher_to_keep_accepted_application) { create(:application, :accepted, :for_cohort_starting_on, teacher: teacher_to_keep, course:, registration_starts_at: Date.new(2021, 6, 1)) }

  let!(:teacher_to_merge_rejected_application) { create(:application, :rejected, :for_cohort_starting_on, teacher: teacher_to_merge, course:, registration_starts_at: Date.new(2021, 7, 1)) }
  let!(:teacher_to_merge_pending_application) { create(:application, :pending, :for_cohort_starting_on, teacher: teacher_to_merge, course:, registration_starts_at: Date.new(2021, 8, 1)) }
  let!(:teacher_to_merge_accepted_application) { create(:application, :accepted, :for_cohort_starting_on, teacher: teacher_to_merge, course:, registration_starts_at: Date.new(2021, 9, 1)) }

  let!(:existing_participant_id_change) { create(:participant_id_change, teacher: teacher_to_merge) }

  it "does not expose internal attributes" do
    expect { described_class.new(teacher_to_merge:, teacher_to_keep:).teacher_to_merge }.to raise_error(NameError)
    expect { described_class.new(teacher_to_merge:, teacher_to_keep:).teacher_to_keep }.to raise_error(NameError)
  end

  describe ".call" do
    subject { described_class.new(teacher_to_merge:, teacher_to_keep:).call(dry_run:) }

    context "when dry run false" do
      let(:dry_run) { false }

      it "moves all applications from the teacher to merge to the teacher to keep" do
        subject
        expect(teacher_to_keep.applications.to_a).to contain_exactly(teacher_to_keep_rejected_application,
                                                                     teacher_to_keep_pending_application,
                                                                     teacher_to_keep_accepted_application,
                                                                     teacher_to_merge_rejected_application,
                                                                     teacher_to_merge_pending_application,
                                                                     teacher_to_merge_accepted_application)
      end

      it "archives the teacher to merge" do
        subject
        expect(teacher_to_merge.reload).to be_archived
      end

      it "keeps the teacher to keep" do
        subject
        expect(teacher_to_keep).not_to be_archived
      end

      it "creates a participant id change" do
        subject
        expect(teacher_to_keep.participant_id_changes.first).to have_attributes(from_participant_id: teacher_to_merge.ecf_id, to_participant_id: teacher_to_keep.ecf_id)
      end

      it "moves existing participant id changes" do
        subject
        expect(existing_participant_id_change.reload.teacher).to eq teacher_to_keep
      end

      context "when there is already a participant id change" do
        before { create(:participant_id_change, teacher: teacher_to_keep, from_participant_id: teacher_to_merge.ecf_id, to_participant_id: teacher_to_keep.ecf_id) }

        it "does not create a duplicate participant id change" do
          subject
          expect(teacher_to_keep.participant_id_changes).to contain_exactly(
            an_object_having_attributes(from_participant_id: teacher_to_merge.ecf_id, to_participant_id: teacher_to_keep.ecf_id),
            existing_participant_id_change.reload,
          )
        end
      end

      context "when only the teacher to merge has a one_login_id" do
        context "when set_one_login_id is false" do
          it "does not update the teacher to keep one_login_id" do
            expect { subject }.not_to(change { teacher_to_keep.reload.one_login_id })
          end
        end

        context "when set_one_login_id is true" do
          subject { described_class.new(teacher_to_merge:, teacher_to_keep:, set_one_login_id: true).call(dry_run:) }

          it "sets the teacher to keep one_login_id to the one from the teacher to merge" do
            expect { subject }.to change { teacher_to_keep.reload.one_login_id }.to(teacher_to_merge.one_login_id)
          end
        end
      end
    end

    context "when dry run true" do
      let(:dry_run) { true }

      it "does not change any teachers" do
        expect { subject }.not_to(change { Teacher.all.pluck(:archived_at) })
      end

      it "does not change any applications" do
        expect { subject }.not_to(change { Application.all.pluck(:teacher_id) })
      end
    end
  end
end
