DECLARATION = {
  v1: {
    description: "The details of a declaration",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        type: :string,
        enum: %w[
          declaration
        ],
        example: "declaration",
      },
      attributes: {
        required: %i[
          application_id
          declaration_type
          declaration_date
          course_identifier
          state
          updated_at
        ],
        properties: {
          application_id: {
            description: "The unique identifier of the application",
            type: :string,
            format: :uuid,
            nullable: false,
            example: "db3a7848-7308-4879-942a-c4a70ced400a",
          },
          participant_id: {
            description: "The unique identifier of this participant declaration record",
            type: :string,
            format: :uuid,
            nullable: false,
            example: "db3a7848-7308-4879-942a-c4a70ced400a",
          },
          declaration_type: {
            description: "The event declaration type",
            type: :string,
            nullable: false,
            example: "started",
            enum: Milestone::DECLARATION_TYPES,
          },
          course_identifier: {
            description: "The course this application relates to",
            type: :string,
            nullable: false,
            example: Course::IDENTIFIERS.first,
            enum: Course::IDENTIFIERS,
          },
          declaration_date: {
            description: "The event declaration date",
            type: :string,
            nullable: false,
            example: "2021-05-31T02:22:32Z",
          },
          state: {
            description: "Indicates the state of this payment declaration",
            type: :string,
            nullable: false,
            example: "submitted",
            enum: Declaration.states.keys + ClawbackDeclaration.states.keys,
          },
          has_passed: {
            description: "Whether the participant has failed or passed",
            type: :boolean,
            nullable: true,
            example: true,
          },
          ineligible_for_funding_reason: {
            description: "If the declaration is ineligible, the reason why",
            type: "string",
            enum: %w[duplicate_declaration],
            nullable: true,
            example: "duplicate_declaration",
          },
          delivery_partner_id: {
            description: "The delivery partner ID",
            type: :string,
            format: :uuid,
            required: true,
            nullable: true,
            example: "524df095-f9bf-4f9d-ba4c-772545a99e60",
          },
          delivery_partner_name: {
            description: "The delivery partner name",
            type: :string,
            required: true,
            nullable: true,
            example: "Foo education",
          },
          secondary_delivery_partner_id: {
            description: "The secondary delivery partner ID",
            type: :string,
            format: :uuid,
            required: true,
            nullable: true,
            example: "f0de7abf-399b-4e68-83de-2c33b503810c",
          },
          secondary_delivery_partner_name: {
            description: "The secondary delivery partner name",
            type: :string,
            required: true,
            nullable: true,
            example: "Bar education",
          },
          statement_id: {
            description: "Unique ID of the statement the declaration will be paid as part of",
            type: "string",
            format: "uuid",
            example: "cd3a12347-7308-4879-942a-c4a70ced400a",
            nullable: true,
          },
          clawback_declaration_id: {
            description: "Unique id of the claw back declaration set when voiding a paid declaration, if any",
            type: "string",
            format: "uuid",
            example: "cd3a12347-7308-4879-942a-c4a70ced400a",
            nullable: true,
          },
          paid_declaration_id: {
            description: "Unique id of the paid declaration which triggered the claw back, if any",
            type: "string",
            format: "uuid",
            example: "cd3a12347-7308-4879-942a-c4a70ced400a",
            nullable: true,
          },
          uplift_paid: {
            description: "If participant is eligible for uplift, whether it has been paid as part of this declaration",
            type: "boolean",
            example: true,
          },
          lead_provider_name: {
            description: "The name of the provider that submitted the declaration",
            type: "string",
            example: "Example Institute",
            nullable: false,
          },
          created_at: {
            description: "The date the application was created",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
        },
      },
    },
  },
}.freeze
