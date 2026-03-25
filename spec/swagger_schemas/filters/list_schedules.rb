LIST_SCHEDULES_FILTER = {
  v1: {
    description: "Filter schedules to return more specific results",
    type: "object",
    properties: {
      cohort: {
        description: "Return schedules associated to the specified cohort or cohorts. This is a comma delimited string of years.",
        type: "string",
        example: "2025,2026",
      },
    },
  },
}.freeze
