LIST_COURSE_COHORTS_FILTER = {
  v1: {
    description: "Filter schedules to return more specific results",
    type: "object",
    properties: {
      cohort: {
        description: "Return schedules associated to the specified academic year. This is a comma delimited string of years.",
        type: "string",
        example: "2025,2026",
      },
    },
  },
}.freeze
