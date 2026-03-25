DECLARATION_REQUEST = {
  description: "A declaration data request",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A declaration data request",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[
            declaration
          ],
          example: "declaration",
        },
        attributes: {
          required: true,
          anyOf: [
            { "$ref": "#/components/schemas/DeclarationStartedRequest" },
            { "$ref": "#/components/schemas/DeclarationCompletedRequest" },
          ],
        },
      },
    },
  },
}.freeze
