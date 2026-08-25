COURSE_COHORT = {
  v1: {
    description: "A single schedule",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "course_cohort",
        enum: %w[
          course_cohort
        ],
      },
      attributes: {
        properties: {
          course_identifier: {
            description: "The course this application relates to",
            type: :string,
            nullable: false,
            example: Course::IDENTIFIERS.first,
            enum: Course::IDENTIFIERS,
          },
          schedule_identifier: {
            description: "The new schedule of the participant",
            nullable: true,
            type: :string,
            example: CourseCohort.term_identifiers.values.first,
            enum: CourseCohort.term_identifiers.values,
          },
          cohort: {
            description: "The requested academic years",
            type: :string,
            example: "2025",
          },
        },
      },
    },
  },
}.freeze
