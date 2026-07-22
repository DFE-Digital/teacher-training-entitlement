module Milestones
  class Create
    include ActiveModel::Model

    def initialize(course_cohort:, **attributes)
      @milestone_attributes = attributes.with_indifferent_access
      @course_cohort = course_cohort
    end

    def call
      @milestone = @course_cohort.milestones.new(@milestone_attributes)

      unless @milestone.valid?
        @milestone.errors.each { |error| errors.add(error.attribute, error.message) }
        return
      end

      ActiveRecord::Base.transaction do
        @milestone.save!
        @milestone.attach_statements!
      end
    end
  end
end
