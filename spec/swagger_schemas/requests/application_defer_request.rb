APPLICATION_DEFER_REQUEST = {
  description: "An application defer request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "An application defer request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          required: true,
          example: "application",
        },
        attributes: {
          description: "A application defer request attributes",
          type: :object,
          required: %i[reason],
          properties: {
            reason: {
              description: "The reason for the deferral",
              required: true,
              nullable: false,
              type: :string,
              example: ::Applications::Defer::DEFERRAL_REASONS.first,
              enum: ::Applications::Defer::DEFERRAL_REASONS,
            },
          },
        },
      },
    },
  },
}.freeze
