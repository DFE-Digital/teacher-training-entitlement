APPLICATION_CHANGE_SCHEDULE_REQUEST = {
  description: "The change schedule request for an application",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "An application change schedule request data",
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
          description: "An application change schedule request attributes",
          type: :object,
          required: %i[cohort_id],
          properties: {
            cohort_id: {
              "$ref": "#/components/schemas/IDAttribute",
              description: "cohort id for a same course as the application is enrolled in",
              required: true,
              nullable: false,
            },
          },
        },
      },
    },
  },
}.freeze
