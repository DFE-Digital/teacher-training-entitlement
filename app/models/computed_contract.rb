class ComputedContract
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :recruitment_target, :integer
  attribute :teacher_funding, :decimal
  attribute :service_fee, :decimal
  attribute :course_cohort

  class << self
    def load_from(contract)
      new.tap do |c|
        c.assign_attributes(
          c.attributes_from(contract),
        )
      end
    end

    def generic(lead_provider:, course:)
      load_from(ContractYear.find_by(lead_provider:, course:, academic_year: nil))
    end

    def academic_year_amendment(lead_provider:, course:, academic_year:)
      return load_from(nil) if academic_year.nil?

      load_from(ContractYear.find_by(lead_provider:, course:, academic_year:))
    end

    def course_cohort_amendment(lead_provider:, course_cohort:)
      load_from(course_cohort.course_cohort_providers.find_by!(lead_provider:))
    end

    def draw(lead_provider:, course_cohort:)
      course = course_cohort.course
      contract = generic(lead_provider:, course:)
        .apply_amendment(academic_year_amendment(lead_provider:, course:, academic_year: course_cohort.academic_year))
        .apply_amendment(course_cohort_amendment(lead_provider:, course_cohort:))

      contract.course_cohort = course_cohort
      contract
    end
  end

  def apply_amendment(contract)
    attrs = attributes
              .merge(attributes_from(contract))
              .compact

    self.class.new(attrs)
  end

  def attributes_from(contract)
    Hash(contract&.attributes)
      .slice(*attribute_names)
      .compact
  end
end
