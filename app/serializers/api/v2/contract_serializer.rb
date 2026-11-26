module API
  module V2
    # Minimal contract resource (a course cohort). Declaration windows and
    # application-specific dates are added by the contracts endpoints; the
    # attributes here are shared by every application on the contract.
    class ContractSerializer
      include JSONAPI::Serializer

      set_type :contract
      set_id :ecf_id

      attribute :academic_year
      attribute(:course) { |course_cohort| course_cohort.course.identifier }
      attribute(:term, &:term_identifier)
    end
  end
end
