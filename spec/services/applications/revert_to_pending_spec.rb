require "rails_helper"

RSpec.describe Applications::RevertToPending, type: :model do
  let(:admin_user) { create(:admin) }
  let(:application) { create(:application, :accepted, :without_funded_place) }

  subject(:instance) { described_class.new(application:, admin_user:) }

  describe "#valid?" do
    context "with status attribute" do
      subject { instance.tap(&:valid?).errors.messages[:status] }

      context "with accepted application" do
        it { is_expected.to be_empty }
      end

      context "with rejected application" do
        let(:application) { create(:application, :rejected) }

        it { is_expected.to be_empty }
      end

      context "with rejected application and no admin user" do
        let(:admin_user) { nil }
        let(:application) { create(:application, :rejected) }

        it { is_expected.not_to be_empty }
      end

      context "with pending application" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to be_empty }
      end
    end

    context "with declarations" do
      subject { instance.tap(&:valid?).errors.full_messages }

      context "when they prevent reverting to pending" do
        before { create(:declaration, :eligible, application:) }

        it { is_expected.to include(/already declarations/i) }
      end

      context "when they do not prevent reverting to pending" do
        before { create(:declaration, :ineligible, application:) }

        it { is_expected.not_to include(/already declarations/i) }
      end
    end
  end

  describe "#revert" do
    subject(:instance) { described_class.new(application:, admin_user:) }

    context "when valid" do
      it "returns true" do
        expect(instance.revert).to be true
      end

      it "updates status" do
        expect { instance.revert }
          .to change { application.reload.status }
                     .from(Application::ACCEPTED)
                     .to(Application::PENDING)
      end

      it "empties the funded_place attribute" do
        expect { instance.revert }
          .to change { application.reload.funded_place }
                     .from(false)
                     .to(nil)
      end

      it "creates a pending state change event" do
        expect { instance.revert }
          .to change { application.state_changes.count }.by(1)
        expect(application.state_changes.last.event).to eq(Application::PENDING)
      end
    end

    context "when the application is rejected and an admin user is present" do
      let(:application) { create(:application, :rejected) }

      it "updates status" do
        expect { instance.revert }
          .to change { application.reload.status }
          .from(Application::REJECTED)
          .to(Application::PENDING)
      end
    end

    context "when the application is rejected and an admin user is not present" do
      subject(:instance) { described_class.new(application:) }

      let(:application) { create(:application, :rejected) }

      it "does not update status" do
        expect { instance.revert }
          .not_to(change { application.reload.status })
      end
    end

    context "when already pending" do
      let :application do
        create(:application, :pending, :with_funded_place).tap do |application|
          create(:declaration, :voided, application:)
        end
      end

      it "returns false" do
        expect(instance.revert).to be false
      end

      it "succeeds but does not change the attributes" do
        expect { instance.revert }
          .to not_change { application.reload.status }
              .and not_change(application, :funded_place)
      end

      it "succeeds but does not remove application_events" do
        expect { instance.revert }
          .to not_change(application.application_events, :count)
      end

      it "succeeds but does not remove declarations" do
        expect { instance.revert }
          .to not_change(application.declarations, :count)
      end
    end

    context "when application already has declarations" do
      Declaration::REVERTABLE_STATES.each do |declaration_state|
        context "with a revertable state: #{declaration_state}" do
          let(:application) { create(:declaration, declaration_state).application }

          it "returns true" do
            expect(instance.revert).to be true
          end

          it "updates the state" do
            expect { instance.revert }
              .to change { application.reload.status }
                  .from(Application::ACCEPTED)
                  .to(Application::PENDING)
              .and(not_change { application.declarations.count })
          end
        end
      end

      Declaration.states.keys.excluding(Declaration::REVERTABLE_STATES).each do |declaration_state|
        context "with a state that cannot be reverted: #{declaration_state}" do
          let(:application) { create(:declaration, declaration_state).application }

          it "returns false" do
            expect(instance.revert).to be false
          end

          it "does not change the status" do
            expect { instance.revert }
              .to not_change { application.reload.status }
              .and(not_change { application.declarations.count })
          end
        end
      end
    end
  end
end
