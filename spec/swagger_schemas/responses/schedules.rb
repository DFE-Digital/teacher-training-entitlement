SCHEDULES_RESPONSE = {
  v1: {
    description: "A list of schedules",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        type: :array,
        items: { "$ref": "#/components/schemas/Schedule" },
      },
    },
  },
}.freeze
