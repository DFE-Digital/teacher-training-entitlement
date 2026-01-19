module CourseGroups
  class Reception
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :course_group
    attribute :cohort

    delegate :schedules, to: :course_group

    def schedule
      # Default
      schedules.find_by!(cohort:, identifier: "tte-reception-autumn")
    end
  end
end
