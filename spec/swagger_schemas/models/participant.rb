PARTICIPANT = {
  v1: {
    description: "The details of an Participant",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "participant",
        enum: %w[participant],
      },
      attributes: {
        properties: {
          participant_id: {
            description: "The unique identifier of this participant",
            type: :string,
            format: :uuid,
            nullable: false,
            example: "db3a7848-7308-4879-942a-c4a70ced400a",
          },
          full_name: {
            description: "The full name of this participant",
            type: :string,
            nullable: false,
            example: "Isabelle MacDonald",
          },
          email: {
            description: "The email address registered for this participant",
            type: :string,
            nullable: false,
            example: "isabelle.macdonald2@some-school.example.com",
          },
          courses: {
            description: "The type of course(s) the participant is enrolled in",
            type: :array,
            items: {
              type: :string,
              nullable: false,
              example: Course::IDENTIFIERS.first,
              enum: Course::IDENTIFIERS,
            },
          },
          funded_places: {
            description: "Information about the funded place(s) the participant is enrolled in",
            type: :array,
            items: {
              type: :object,
              required: %i[course funded_place application_id],
              properties: {
                course: {
                  description: "The type of course the participant is enrolled in",
                  type: :string,
                  nullable: false,
                  example: Course::IDENTIFIERS.first,
                  enum: Course::IDENTIFIERS,
                },
                funded_place: {
                  description: "Indicates whether or not this participant’s training is being funded by DfE",
                  type: :boolean,
                  example: true,
                  nullable: true,
                },
                application_id: {
                  description: "The ID of the application that was accepted to create this enrolment",
                  type: :string,
                  format: :uuid,
                  nullable: false,
                  example: "db3a7848-7308-4879-942a-c4a70ced400a",
                },
              },
            },
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this participant",
            type: :string,
            example: "1234567",
            nullable: true,
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
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v2][:properties][:attributes][:properties].except!(:participant_id, :courses, :funded_places)
  h[:v2][:properties][:attributes][:properties][:enrolments] = {
    description: "Information about the course(s) the participant is enrolled in",
    type: :array,
    items: {
      description: "The details of an Participant enrolment",
      type: :object,
      required: %i[course_identifier application_id eligible_for_funding status],
      properties: {
        course_identifier: {
          description: "The course this application relates to",
          type: :string,
          nullable: false,
          example: Course::IDENTIFIERS.first,
          enum: Course::IDENTIFIERS,
        },
        schedule_identifier: {
          description: "The new schedule of the participant",
          nullable: true,
          type: :string,
          example: Schedule::IDENTIFIERS.first,
          enum: Schedule::IDENTIFIERS,
        },
        cohort: {
          description: "Indicates which call-off contract would fund this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Once a provider accepts an application, they may change a participant's cohort up until the point of submitting a started declaration.",
          type: :string,
          nullable: true,
          example: "2022",
        },
        application_id: {
          description: "The ID of the application that was accepted to create this enrolment",
          type: :string,
          format: :uuid,
          nullable: false,
          example: "db3a7848-7308-4879-942a-c4a70ced400a",
        },
        eligible_for_funding: {
          description: "Indicates whether this participant would be eligible for funding from the DfE",
          type: :boolean,
          nullable: false,
          example: true,
        },
        status: {
          description: "The status of the participant",
          type: :string,
          enum: Application::API_STATUSES,
          example: Application::API_STATUSES.first,
        },
        school_urn: {
          description: "The Unique Reference Number (URN) of the school where this participant is employed",
          type: :string,
          nullable: true,
          example: "106286",
        },
        funded_place: {
          description: "Indicates whether or not this participant’s training is being funded by DfE",
          nullable: true,
          type: :boolean,
          example: true,
        },
      },
    },
  }

  h[:v1] = h[:v2].deep_dup
  h[:v1][:properties][:attributes][:properties].except!(:email)
  h[:v1][:properties][:attributes][:properties][:enrolments][:items][:required] << :email
  h[:v1][:properties][:attributes][:properties][:enrolments][:items][:properties].merge!({
    email: {
      description: "The email address registered for this participant",
      type: :string,
      nullable: false,
      example: "isabelle.macdonald2@some-school.example.com",
    },
    withdrawal: {
      description: "The details of an Participant withdrawal",
      type: :object,
      nullable: true,
      required: %i[reason date],
      example: nil,
      properties: {
        reason: {
          description: "The reason a participant was withdrawn",
          type: :string,
          nullable: false,
          example: ::Applications::Withdraw::WITHDRAWAL_REASONS.first,
          enum: ::Applications::Withdraw::WITHDRAWAL_REASONS,
        },
        date: {
          description: "The date and time the participant was withdrawn",
          type: :string,
          nullable: false,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      },
    },
    deferral: {
      description: "The details of an Participant deferral",
      type: :object,
      nullable: true,
      required: %i[reason date],
      example: nil,
      properties: {
        reason: {
          description: "The reason a participant was deferred",
          type: :string,
          nullable: false,
          example: ::Applications::Defer::DEFERRAL_REASONS.first,
          enum: ::Applications::Defer::DEFERRAL_REASONS,
        },
        date: {
          description: "The date and time the participant was deferred",
          type: :string,
          nullable: false,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      },
    },
    created_at: {
      description: "The date and time the participant was accepted",
      type: :string,
      nullable: false,
      format: :"date-time",
      example: "2021-05-31T02:21:32.000Z",
    },
  })
  h[:v1][:properties][:attributes][:properties][:participant_id_changes] = {
    description: "Information about the Participant ID changes",
    type: :array,
    items: {
      description: "The details of an Participant ID change",
      type: :object,
      required: %i[from_participant_id to_participant_id changed_at],
      properties: {
        from_participant_id: {
          description: "The unique identifier of the changed from participant training record.",
          type: :string,
          format: :uuid,
          example: "23dd8d66-e11f-4139-9001-86b4f9abcb02",
        },
        to_participant_id: {
          description: "The unique identifier of the changed to participant training record.",
          type: :string,
          format: :uuid,
          example: "ac3d1243-7308-4879-942a-c4a70ced400a",
        },
        changed_at: {
          description: "The date and time the Participant ID change",
          type: :string,
          format: :"date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
      },
    },
  }
}.freeze
