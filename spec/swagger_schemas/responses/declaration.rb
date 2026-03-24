DECLARATION_RESPONSE = {
  v1: {
    description: "A single declaration.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/Declaration",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = h[:v1]
}.freeze
