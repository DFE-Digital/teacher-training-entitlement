# frozen_string_literal: true

require "rails_helper"
require "api/version"

Dir[Rails.root.join("spec/swagger_schemas/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("public/api/docs").to_s

  config.openapi_strict_schema_validation = true

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = API::Version.all.each_with_object({}) do |version, hash|
    hash["#{version}/swagger.yaml"] = {
      openapi: "3.0.1",
      info: {
        title: "Teacher Training Entitlement (TTE) API",
        version:,
      },
      externalDocs: {
        description: "Find out more about Swagger",
        url: "https://swagger.io/",
      },
      paths: {},
      servers: [
        {
          url: "/",
          description: "API endpoint",
        },
      ],
      components: {
        securitySchemes: {
          api_key: {
            description: "Bearer token",
            type: :apiKey,
            name: "Authorization",
            in: :header,
          },
        },
        schemas: {
          PaginationFilter: PAGINATION_FILTER,
          ListApplicationsFilter: LIST_APPLICATIONS_FILTER[version],
          ListParticipantsFilter: LIST_PARTICIPANTS_FILTER[version],
          ListDeclarationsFilter: LIST_DECLARATIONS_FILTER[version],
          ListParticipantOutcomesFilter: LIST_PARTICIPANT_OUTCOMES_FILTER,
          ListStatementsFilter: LIST_STATEMENTS_FILTER[version],
          ListCourseCohortsFilter: LIST_COURSE_COHORTS_FILTER[version],

          UnauthorisedResponse: UNAUTHORISED_RESPONSE,
          NotFoundResponse: NOT_FOUND_RESPONSE,
          BadRequestResponse: BAD_REQUEST_RESPONSE,
          UnprocessableEntityResponse: UNPROCESSABLE_CONTENT_RESPONSE,
          IDAttribute: ID_ATTRIBUTE,
          ApplicationResponse: APPLICATION_RESPONSE[version],
          ApplicationsResponse: APPLICATIONS_RESPONSE[version],
          Application: APPLICATION[version],
          ApplicationAcceptRequest: APPLICATION_ACCEPT_REQUEST[version],
          ApplicationChangeFundedPlaceRequest: APPLICATION_CHANGE_FUNDED_PLACE_REQUEST,
          ApplicationResumeRequest: APPLICATION_RESUME_REQUEST,
          ApplicationDeferRequest: APPLICATION_DEFER_REQUEST,
          ApplicationWithdrawRequest: APPLICATION_WITHDRAW_REQUEST,
          ApplicationChangeScheduleRequest: APPLICATION_CHANGE_SCHEDULE_REQUEST,

          ParticipantResponse: PARTICIPANT_RESPONSE[version],
          ParticipantsResponse: PARTICIPANTS_RESPONSE[version],
          Participant: PARTICIPANT[version],

          ParticipantOutcome: PARTICIPANT_OUTCOME[version],
          ParticipantOutcomeCreateRequest: PARTICIPANT_OUTCOME_CREATE_REQUEST,
          ParticipantOutcomeResponse: PARTICIPANT_OUTCOME_RESPONSE[version],
          ParticipantOutcomesResponse: PARTICIPANT_OUTCOMES_RESPONSE[version],

          StatementResponse: STATEMENT_RESPONSE[version],
          StatementsResponse: STATEMENTS_RESPONSE[version],
          Statement: STATEMENT[version],

          SortingOptions: SORTING_OPTIONS[version],

          ListDeliveryPartnersFilter: LIST_DELIVERY_PARTNERS_FILTER[version],
          DeliveryPartner: DELIVERY_PARTNER[version],
          DeliveryPartnerResponse: DELIVERY_PARTNER_RESPONSE[version],
          DeliveryPartnersResponse: DELIVERY_PARTNERS_RESPONSE[version],
          DeliveryPartnersSortingOptions: DELIVERY_PARTNERS_SORTING_OPTIONS[version],

          Declaration: DECLARATION[version],
          DeclarationResponse: DECLARATION_RESPONSE[version],
          DeclarationsResponse: DECLARATIONS_RESPONSE[version],
          DeclarationRequest: DECLARATION_REQUEST,
          DeclarationStartedRequest: DECLARATION_STARTED_REQUEST,
          # DeclarationRetainedRequest: DECLARATION_RETAINED_REQUEST,
          DeclarationCompletedRequest: DECLARATION_COMPLETED_REQUEST,
          DeclarationChangeDeliveryPartnerRequest: DECLARATION_CHANGE_DELIVERY_PARTNER_REQUEST,

          CourseCohort: COURSE_COHORT[version],
          CourseCohortResponse: COURSE_COHORT_RESPONSE[version],
          CourseCohortsResponse: COURSE_COHORTS_RESPONSE[version],
        }.compact,
      },
    }
  end
  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
