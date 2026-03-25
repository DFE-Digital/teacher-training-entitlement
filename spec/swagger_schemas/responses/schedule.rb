SCHEDULE_RESPONSE = {
  v1: {
    description: "A single schedule",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/Schedule",
      },
    },
  },
}.freeze
