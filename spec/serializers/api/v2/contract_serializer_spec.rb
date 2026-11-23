require "rails_helper"

RSpec.describe API::V2::ContractSerializer do
  subject(:data) { described_class.new(course_cohort).serializable_hash[:data] }

  let(:course_cohort) { create(:application).course_cohort }

  it "identifies the contract by course cohort ecf_id" do
    expect(data.slice(:id, :type)).to eq(id: course_cohort.ecf_id, type: :contract)
  end

  it "exposes academic year, course and term" do
    expect(data[:attributes]).to eq(
      academic_year: course_cohort.academic_year,
      course: course_cohort.course.identifier,
      term: course_cohort.term_identifier,
    )
  end
end
