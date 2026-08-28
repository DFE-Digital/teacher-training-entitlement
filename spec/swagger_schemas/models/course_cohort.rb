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
        example: "schedule",
        enum: %w[
          schedule
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
            example: [Course::IDENTIFIERS.first, CourseCohort::TERM_IDENTIFIERS.keys.first].join("-"),
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
