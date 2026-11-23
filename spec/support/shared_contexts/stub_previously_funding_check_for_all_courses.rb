RSpec.shared_context("Stub previously funding check for all courses") do # rubocop:disable RSpec/ContextWording:
  let(:trn) { raise NotImplementedError }

  before do
    teacher = create(:teacher, trn:, email: "user@example.com")
    Course.all.find_each do |course|
      create(:application, :accepted, :eligible_for_funding, teacher:, course:)
    end
  end
end
