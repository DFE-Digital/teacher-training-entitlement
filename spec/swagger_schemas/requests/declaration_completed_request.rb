DECLARATION_COMPLETED_REQUEST = {
  description: "An completed declaration",
  type: :object,
  required: %i[
    declaration_date
    has_passed
    delivery_partner_id
  ],
  additionalProperties: false,
  properties: {
    declaration_date: {
      description: "The event declaration date",
      type: :string,
      required: true,
      nullable: false,
      format: "date-time",
      example: "2021-05-31T02:21:32Z",
    },
    has_passed: {
      description: "Whether the participant has failed or passed",
      type: :boolean,
      required: true,
      nullable: false,
      example: true,
    },
    delivery_partner_id: {
      description: "The delivery partner ID",
      type: :string,
      format: :uuid,
      required: false,
      nullable: false,
      example: "524df095-f9bf-4f9d-ba4c-772545a99e60",
    },
    secondary_delivery_partner_id: {
      description: "The secondary delivery partner ID",
      type: :string,
      format: :uuid,
      required: false,
      nullable: false,
      example: "f0de7abf-399b-4e68-83de-2c33b503810c",
    },
  },
  example: {
    declaration_date: "2021-05-31T02:21:32Z",
    has_passed: true,
    delivery_partner_id: "524df095-f9bf-4f9d-ba4c-772545a99e60",
  },
}.freeze
