module Statements
  class CourseCohortCalculator
    def initialize(statement:, course_cohort:)
      @statement = statement
      @course_cohort = course_cohort
    end

    def funded_rows
      rows = milestones.map do |milestone|
        declarations = funded_declarations[milestone] || []
        count = declarations.size
        payment = declarations.first&.value
        total = payment ? count * payment : 0
        [milestone.declaration_type.humanize.capitalize, count, payment, total]
      end
      total_count = rows.sum { |r| r[1] }
      total_payment = rows.sum { |r| r[3] }
      rows << ["Total", total_count, nil, total_payment]
    end

    def self_funded_rows
      rows = milestones.map do |milestone|
        declarations = self_funded_declarations[milestone] || []
        [milestone.declaration_type.humanize.capitalize, declarations.size]
      end
      rows << ["Total", rows.sum { |r| r[1] }]
    end

  private

    attr_reader :statement, :course_cohort

    def milestones
      @milestones ||= course_cohort.milestones.to_a
    end

    def funded_declarations
      @funded_declarations ||= course_cohort_declarations
        .where(applications: { funded_place: true })
        .group_by(&:milestone)
    end

    def self_funded_declarations
      @self_funded_declarations ||= course_cohort_declarations
        .where(applications: { funded_place: [nil, false] })
        .group_by(&:milestone)
    end

    def course_cohort_declarations
      statement.declarations.billable
        .joins(:application)
        .includes(:milestone)
        .where(milestones: { course_cohort_id: course_cohort.id })
    end
  end
end
