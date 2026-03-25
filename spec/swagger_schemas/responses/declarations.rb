DECLARATIONS_RESPONSE = {
  v1: {
    description: "A list of declarations.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        type: :array,
        items: { "$ref": "#/components/schemas/Declaration" },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = h[:v1]
}.freeze
