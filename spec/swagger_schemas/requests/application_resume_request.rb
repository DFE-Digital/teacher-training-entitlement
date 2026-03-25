APPLICATION_RESUME_REQUEST = {
  description: "An application resume request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "An application resume request data",
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
          description: "An application resume request attributes",
          type: :object,
          required: %i[schedule_id],
          properties: {
            schedule_id: {
              "$ref": "#/components/schemas/IDAttribute",
              description: "schedule id for a same course as the application is enrolled in",
              required: true,
              nullable: false,
            },
          },
        },
      },
    },
  },
}.freeze
