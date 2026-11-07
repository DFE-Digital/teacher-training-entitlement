LIST_DELIVERY_PARTNERS_FILTER = {
  v1: {
    description: "Filter delivery partners to return more specific results",
    type: "object",
    properties: {
      cohort: {
        description: "Return only delivery partners from the specified cohort.",
        type: "string",
        example: "2022",
      },
      course: {
        description: "Return only delivery partners for the specified course or courses. This is a comma delimited string of course identifiers.",
        type: "string",
        example: "tte-early-years",
      },
    },
  },
}.freeze
