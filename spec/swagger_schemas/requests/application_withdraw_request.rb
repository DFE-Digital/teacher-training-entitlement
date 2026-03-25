APPLICATION_WITHDRAW_REQUEST = {
  description: "An application withdraw request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "An application withdraw request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          example: "application",
          required: true,
        },
        attributes: {
          description: "An application withdraw request attributes",
          type: :object,
          required: %i[reason],
          properties: {
            reason: {
              description: "The reason for the withdrawal",
              required: true,
              nullable: false,
              type: :string,
              example: ::Applications::Withdraw::WITHDRAWAL_REASONS.first,
              enum: ::Applications::Withdraw::WITHDRAWAL_REASONS,
            },
          },
        },
      },
    },
  },
}.freeze
