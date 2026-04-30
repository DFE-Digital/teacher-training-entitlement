LIST_PARTICIPANTS_FILTER = {
  v1: {
    description: "Filter applications to return more specific results",
    type: :object,
    properties: {
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: :string,
        example: "2021-05-13T11:21:55Z",
      },
      status: {
        description: "Return only records with specified status or statuses",
        type: :string,
        enum: Application::STATUSES,
        example: Application::STATUSES[0..2].join(","),
      },
      from_participant_id: {
        description: "Return only records that have this from Participant ID",
        type: :string,
        example: "7e5bcdbf-c818-4961-8da5-439cab1984e0",
      },
    },
  },
}.freeze
