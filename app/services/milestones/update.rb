module Milestones
  class Update
    include ActiveModel::Model

    def initialize(milestone:, **attributes)
      @milestone = milestone
      @milestone_attributes = attributes.with_indifferent_access
    end

    def call
      @milestone.assign_attributes(@milestone_attributes)

      unless @milestone.valid?
        @milestone.errors.each { |error| errors.add(error.attribute, error.message) }
        return
      end

      ActiveRecord::Base.transaction do
        @milestone.milestone_statements.destroy_all
        @milestone.save!
        @milestone.attach_statements!
      end
    end
  end
end
