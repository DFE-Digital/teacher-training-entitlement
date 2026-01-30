STATEMENT_RESPONSE = {
  v1: {
    description: "A financial statement.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/Statement",
      },
    },
  },
}.freeze
