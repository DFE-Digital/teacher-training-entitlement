module Registrations
  module StepTemplates
    module Courses
      class NpdService < BaseStepTemplateService
        def call
          starting_order = registration_journey.registration_steps.maximum(:order).to_i

          course_start_date = create_step(
            name: "Choose your course start date",
            slug: "course-start-date",
            answer_key: "course_start_date",
            type: RegistrationSteps::CustomView::TYPE,
            order: starting_order + 1,
            answers: [
              { "name" => "Yes", "value" => "yes" },
              { "name" => "I want to start at a later date", "value" => "later" },
            ],
          )
          course_start_date.set_custom_view!(custom_view_class_name: "Registrations::NpdCourseStartDateComponent")

          choose_your_provider = create_step(
            name: "Select your training provider",
            slug: "choose-your-provider",
            answer_key: "lead_provider_id",
            type: "Radio buttons",
            order: starting_order + 2,
            previous_step_id: course_start_date.id,
            answers: LeadProvider.alphabetical.map do |lead_provider|
              { "name" => lead_provider.name, "value" => lead_provider.id.to_s }
            end,
          )

          teacher_catchment = create_step(
            name: "Do you work in England?",
            slug: "teacher-catchment",
            answer_key: "teacher_catchment",
            type: "Radio buttons",
            order: starting_order + 3,
            previous_step_id: choose_your_provider.id,
            answers: [
              { "name" => "Yes", "value" => Questionnaires::TeacherCatchment::ENGLAND },
              { "name" => "No", "value" => Questionnaires::TeacherCatchment::NOT_ENGLAND },
            ],
          )

          work_setting = create_step(
            name: "Tell us where you work",
            slug: "work-setting",
            answer_key: "work_setting",
            type: "Radio buttons",
            order: starting_order + 4,
            previous_step_id: teacher_catchment.id,
            answers: [
              { "name" => "State-funded nursery, pre-school, school or academy trust", "value" => Institution::STATE_FUNDED_INSTITUTION },
              { "name" => "Private nursery, pre-school or school", "value" => Institution::PRIVATE_INSTITUTION },
              { "name" => "Other", "value" => Institution::OTHER },
            ],
          )

          choose_school = create_step(
            name: "Select your workplace",
            slug: "choose-school",
            answer_key: "institution_id",
            type: "Choose institution",
            order: starting_order + 5,
            previous_step_id: work_setting.id,
          )

          # choose_school.add_text!(
          #   text: "Search for your workplace by postcode, unique reference number (URN) or name. If you work for a trust, use the details of one of its schools.",
          #   text_size: "t",
          # )

          possible_funding = create_step(
            name: "Funding eligibility result",
            slug: "possible-funding",
            type: RegistrationSteps::CustomView::TYPE,
            order: starting_order + 6,
            previous_step_id: choose_school.id,
          )
          possible_funding.set_custom_view!(custom_view_class_name: "Registrations::NpdFundingEligibilityResultsComponent")
          possible_funding.add_service!(class_name: "Registrations::FundingEligibility::NpdService",
                                        execute_point: :before_show)

          ineligible_for_funding = create_step(
            name: "Funding eligibility result",
            slug: "ineligible-for-funding",
            type: RegistrationSteps::CustomView::TYPE,
            order: starting_order + 7,
          )
          ineligible_for_funding.set_custom_view!(custom_view_class_name: "Registrations::NpdFundingEligibilityResultsComponent")
          ineligible_for_funding.add_service!(class_name: "Registrations::FundingEligibility::NpdService",
                                              execute_point: :before_show)

          create_step(
            name: "How are you funding your course?",
            slug: "funding-your-course",
            answer_key: "funding",
            type: "Radio buttons",
            order: starting_order + 8,
            previous_step_id: ineligible_for_funding.id,
            answers: [
              { "name" => "My workplace is covering the cost", "value" => "school" },
              { "name" => "My trust is paying", "value" => "trust" },
              { "name" => "I am paying", "value" => "self" },
              { "name" => "My course is being paid for in another way", "value" => "another" },
            ],
          )

          share_provider = create_step(
            name: "Sharing your NPD information",
            slug: "share-provider",
            answer_key: "can_share_choices",
            type: "Checkboxes",
            order: starting_order + 9,
            previous_step_id: possible_funding.id,
            answers: [
              { "name" => "Yes, I agree to share my information",
                "value" => "1" },
            ],
          )

          share_provider.add_text!(
            text: "All the information you enter for your NPD registration will be shared with external organisations including auditors, evaluators, relevant bodies and training providers — this allows your provider to register you onto their course.",
            text_size: "t",
          )

          share_provider.add_text!(
            text: "For more information about who we share your data with read our privacy notice.",
            text_size: "t",
          )

          share_provider.add_text!(
            text: "If you do not agree to share your information you will not be able to progress with your NPD course.",
            text_size: "t",
          )

          check_answers = create_step(
            name: "Check answers",
            slug: "check-answers",
            type: "Check answers",
            order: starting_order + 10,
          )
          check_answers.add_service!(class_name: "Registrations::Courses::Npd::CompletionService",
                                     execute_point: :after_update)
          check_answers.add_redirect!(redirect_path: "/applications/:ecf_id", redirect_state_store_key: "application_ecf_id")

          cannot_register_yet = create_step(
            name: "Cannot register yet",
            slug: "cannot-register-yet",
            type: "Plain",
            order: starting_order + 11,
          )
          cannot_register_yet.add_text!(
            text: "You cannot register for this course start date yet.",
            text_size: "m",
          )

          course_start_date.set_answers!(
            answers: [
              { "name" => "Yes", "value" => "yes" },
              { "name" => "I want to start at a later date", "value" => "later", "next_step_id" => cannot_register_yet.id },
            ],
          )
          teacher_catchment.set_answers!(
            answers: [
              { "name" => "Yes", "value" => Questionnaires::TeacherCatchment::ENGLAND },
              { "name" => "No", "value" => Questionnaires::TeacherCatchment::NOT_ENGLAND, "next_step_id" => ineligible_for_funding.id },
            ],
          )
          work_setting.set_answers!(
            answers: [
              { "name" => "State-funded nursery, pre-school, school or academy trust", "value" => Institution::STATE_FUNDED_INSTITUTION },
              { "name" => "Private nursery, pre-school or school", "value" => Institution::PRIVATE_INSTITUTION, "next_step_id" => ineligible_for_funding.id },
              { "name" => "Other", "value" => Institution::OTHER, "next_step_id" => ineligible_for_funding.id },
            ],
          )

          teacher_catchment.branch_join_step_id = share_provider.id
          work_setting.branch_join_step_id = share_provider.id
          teacher_catchment.save!
          work_setting.save!
        end

      private

        def create_step(name:, slug:, type:, order:, answer_key: nil, answers: [], previous_step_id: nil)
          type_as_param = type.underscore.parameterize.underscore
          config = {}
          config[type_as_param] = { "answers" => answers } if answers.any?
          config["previous_step_id"] = previous_step_id if previous_step_id

          registration_journey.registration_steps.create!(
            name:,
            slug:,
            answer_key:,
            type:,
            order:,
            config:,
          )
        end

        def course_name
          Course.reception&.name || "this course"
        end
      end
    end
  end
end
