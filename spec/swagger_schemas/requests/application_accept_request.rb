APPLICATION_ACCEPT_REQUEST = {
  v1: {
    description: "An application acceptance request",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        description: "An application acceptance request data",
        type: :object,
        required: %i[type attributes],
        properties: {
          type: {
            description: "The data typed",
            type: :string,
            required: true,
            example: "application-accept",
          },
          attributes: {
            description: "An application acceptance request attributes",
            type: :object,
            required: false,
            properties: {
              funded_place: {
                description: "Whether the participant has a funded place",
                nullable: false,
                type: :boolean,
                example: true,
              },
              schedule_identifier: {
                description: "The new schedule of the participant",
                nullable: false,
                type: :string,
                example: Schedule::IDENTIFIERS.first,
                enum: Schedule::IDENTIFIERS,
              },
            },
          },
        },
      },
    },
  },
}.freeze
