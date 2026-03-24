PARTICIPANT_OUTCOME = {
  v1: {
    description: "The details of an outcome",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "outcome",
        enum: %w[
          outcome
        ],
      },
      attributes: {
        properties: {
          state: {
            description: "The state of the outcome (passed or failed)",
            nullable: false,
            type: :string,
            example: ParticipantOutcome.states.keys.first,
            enum: ParticipantOutcome.states.keys,
          },
          completion_date: {
            description: "The date the participant received the assessment outcome for this course",
            nullable: false,
            type: :string,
            example: "2021-05-31T00:00:00+00:00",
          },
          course_identifier: {
            description: "The course this application relates to",
            type: :string,
            nullable: false,
            example: ParticipantOutcomes::Create::PERMITTED_COURSES.first,
            enum: ParticipantOutcomes::Create::PERMITTED_COURSES,
          },
          participant_id: {
            description: "The unique identifier of this participant",
            type: :string,
            nullable: false,
            example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
            format: "uuid",
          },
          created_at: {
            description: "The date you created the participant-outcome record",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:21:32.000Z",
          },
          updated_at: {
            description: "The date and time the participant-outcome record was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          }
        },
      },
    },
  },
}.freeze
