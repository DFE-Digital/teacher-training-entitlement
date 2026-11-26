require "rails_helper"

RSpec.describe Registrations::CheckAnswersComponent, type: :component do
  let(:wizard) { double(course: nil, data: { steps: {} }) }
  let(:wizard_step) { double(wizard:) }

  it "shows an empty state when the wizard has no answers" do
    render_inline(described_class.new(wizard_step:))

    expect(page).to have_text("No answers have been captured yet.")
  end
end
