module Registrations
  module StepTemplates
    class NpqInspiredJourneyService < BaseStepTemplateService
      def call
        location = create_step(
          name: "Do you work in England?",
          slug: "teacher-catchment",
          type: "Radio buttons",
          order: 1,
          answers: %w[Yes No],
        )
        location.add_text!(
          text: "Your workplace location can affect the support available for an NPQ.",
          text_size: "s",
        )

        referral = create_step(
          name: "Were you referred by a return to teaching adviser?",
          slug: "return-to-teaching-referral",
          type: "Radio buttons",
          order: 2,
          previous_step: location,
          answers: %w[Yes No],
        )

        course_start = create_step(
          name: "When do you want to start your course?",
          slug: "course-start-date",
          type: "Radio buttons",
          order: 3,
          previous_step: referral,
          answers: ["Autumn 2026", "Spring 2027", "A later cohort"],
        )

        work_setting = create_step(
          name: "Which setting do you work in?",
          slug: "work-setting",
          type: "Radio buttons",
          order: 4,
          previous_step: course_start,
        )

        school = create_step(
          name: "Choose your school or academy",
          slug: "choose-school",
          type: "Choose institution",
          order: 5,
          previous_step: work_setting,
        )
        school_role = create_step(
          name: "What is your role in the school?",
          slug: "school-role",
          type: "Radio buttons",
          order: 6,
          previous_step: school,
          answers: ["Teacher", "Middle or senior leader", "Headteacher", "Other"],
        )
        create_step(
          name: "What is your employment status at the school?",
          slug: "school-employment-status",
          type: "Radio buttons",
          order: 7,
          previous_step: school_role,
          answers: ["Employed full time", "Employed part time", "On secondment", "Not currently employed there"],
        )

        childcare_kind = create_step(
          name: "What kind of early years setting do you work in?",
          slug: "early-years-setting",
          type: "Radio buttons",
          order: 8,
          previous_step: work_setting,
          answers: ["Nursery attached to a school", "Private nursery", "Childminder", "Other childcare setting"],
        )
        ofsted_registration = create_step(
          name: "Is your early years setting registered with Ofsted?",
          slug: "ofsted-registration",
          type: "Radio buttons",
          order: 9,
          previous_step: childcare_kind,
        )
        childcare_provider = create_step(
          name: "Choose your early years setting",
          slug: "choose-early-years-setting",
          type: "Choose institution",
          order: 10,
          previous_step: ofsted_registration,
        )
        childcare_registration_help = create_step(
          name: "Why can you not provide an Ofsted-registered setting?",
          slug: "childcare-registration-help",
          type: "Radio buttons",
          order: 11,
          previous_step: ofsted_registration,
          answers: ["My setting is not registered", "I cannot find my setting", "I do not know its registration details"],
        )
        early_years_role = create_step(
          name: "What is your role in the early years setting?",
          slug: "early-years-role",
          type: "Radio buttons",
          order: 12,
          previous_step: ofsted_registration,
          answers: ["Early years practitioner", "Room or phase leader", "Setting manager", "Childminder", "Other"],
        )
        ofsted_registration.set_answers!(
          answers: [
            { "name" => "Yes", "next_step_id" => childcare_provider.id },
            { "name" => "No", "next_step_id" => childcare_registration_help.id },
            { "name" => "I do not know", "next_step_id" => childcare_registration_help.id },
          ],
        )
        ofsted_registration.update!(branch_join_step_id: early_years_role.id)

        other_employment = create_step(
          name: "Which best describes your employment?",
          slug: "other-employment",
          type: "Radio buttons",
          order: 13,
          previous_step: work_setting,
          answers: ["Local authority", "Further education", "Higher education", "Independent consultant", "Other"],
        )
        other_role = create_step(
          name: "How is your role connected to education?",
          slug: "other-education-role",
          type: "Checkboxes",
          order: 14,
          previous_step: other_employment,
          answers: ["Teaching", "Leadership", "Teacher development", "School improvement", "Early years"],
        )
        create_step(
          name: "Will an employer support you to complete the course?",
          slug: "employer-support",
          type: "Radio buttons",
          order: 15,
          previous_step: other_role,
          answers: ["Yes", "No", "I am self-employed", "I do not know yet"],
        )

        work_setting.set_answers!(
          answers: [
            { "name" => "A school or academy trust", "next_step_id" => school.id },
            { "name" => "An early years or childcare setting", "next_step_id" => childcare_kind.id },
            { "name" => "Another education setting", "next_step_id" => other_employment.id },
          ],
        )

        course = create_step(
          name: "Which course do you want to take?",
          slug: "choose-your-npq",
          type: "Radio buttons",
          order: 16,
        )

        leadership_responsibility = create_step(
          name: "Do you currently have a leadership responsibility?",
          slug: "leadership-responsibility",
          type: "Radio buttons",
          order: 17,
          previous_step: course,
          answers: ["Yes", "No, but I am preparing for one", "No"],
        )
        teaching_phase = create_step(
          name: "Which phases do you work with?",
          slug: "teaching-phases",
          type: "Checkboxes",
          order: 18,
          previous_step: leadership_responsibility,
          answers: ["Early years", "Primary", "Secondary", "Further education"],
        )
        create_step(
          name: "How much teaching or leadership experience do you have?",
          slug: "teaching-experience",
          type: "Radio buttons",
          order: 19,
          previous_step: teaching_phase,
          answers: ["Less than 2 years", "2 to 5 years", "6 to 10 years", "More than 10 years"],
        )

        senco_status = create_step(
          name: "Which statement describes your SENCO role?",
          slug: "senco-role",
          type: "Radio buttons",
          order: 20,
          previous_step: course,
        )
        senco_start_date = create_step(
          name: "When did you start as a SENCO?",
          slug: "senco-start-date",
          type: RegistrationSteps::CustomStep::TYPE,
          order: 21,
          previous_step: senco_status,
        )
        senco_start_date.set_custom_step!(
          custom_step_class_name: "Forms::NpqInspired::SencoStartDateStepForm",
        )
        senco_readiness = create_step(
          name: "When do you expect to take on SENCO responsibilities?",
          slug: "senco-readiness",
          type: "Radio buttons",
          order: 22,
          previous_step: senco_status,
          answers: ["Within 6 months", "Within a year", "More than a year from now", "I am not sure"],
        )
        senco_responsibilities = create_step(
          name: "Which SENCO responsibilities do you have or expect to take on?",
          slug: "senco-responsibilities",
          type: "Checkboxes",
          order: 23,
          previous_step: senco_status,
          answers: ["Leading SEND provision", "Supporting colleagues", "Working with families", "Working with external services"],
        )
        senco_status.set_answers!(
          answers: [
            { "name" => "I am a SENCO", "next_step_id" => senco_start_date.id },
            { "name" => "I am about to become a SENCO", "next_step_id" => senco_readiness.id },
            { "name" => "I want to become a SENCO", "next_step_id" => senco_readiness.id },
          ],
        )
        senco_status.update!(branch_join_step_id: senco_responsibilities.id)

        teaching_for_mastery = create_step(
          name: "Have you completed a year of the Teaching for Mastery programme?",
          slug: "teaching-for-mastery",
          type: "Radio buttons",
          order: 24,
          previous_step: course,
        )
        maths_approach = create_step(
          name: "How familiar are you with the mastery approach to mathematics?",
          slug: "maths-mastery-understanding",
          type: "Radio buttons",
          order: 25,
          previous_step: teaching_for_mastery,
        )
        maths_preparation = create_step(
          name: "How will you prepare for the mathematics leadership course?",
          slug: "maths-course-preparation",
          type: "Checkboxes",
          order: 26,
          previous_step: maths_approach,
          answers: ["Speak to a maths lead", "Review mastery materials", "Observe mastery teaching", "Discuss support with my school"],
        )
        maths_leadership = create_step(
          name: "What responsibility do you have for mathematics teaching?",
          slug: "maths-leadership-role",
          type: "Radio buttons",
          order: 27,
          previous_step: teaching_for_mastery,
          answers: ["School-wide leadership", "Phase or department leadership", "Classroom teaching", "I am preparing for a leadership role"],
        )
        maths_approach.set_answers!(
          answers: [
            { "name" => "I use it regularly", "next_step_id" => maths_leadership.id },
            { "name" => "I understand the principles", "next_step_id" => maths_leadership.id },
            { "name" => "I am new to the approach", "next_step_id" => maths_preparation.id },
          ],
        )
        maths_approach.update!(branch_join_step_id: maths_leadership.id)
        teaching_for_mastery.set_answers!(
          answers: [
            { "name" => "Yes", "next_step_id" => maths_leadership.id },
            { "name" => "No", "next_step_id" => maths_approach.id },
          ],
        )
        teaching_for_mastery.update!(branch_join_step_id: maths_leadership.id)

        headteacher_status = create_step(
          name: "Are you currently a headteacher?",
          slug: "headteacher-status",
          type: "Radio buttons",
          order: 28,
          previous_step: course,
          answers: ["Yes", "No, but I have a confirmed headteacher post", "No"],
        )
        headship_stage = create_step(
          name: "How long have you been, or when will you become, a headteacher?",
          slug: "headship-stage",
          type: "Radio buttons",
          order: 29,
          previous_step: headteacher_status,
          answers: ["Less than a year", "1 to 2 years", "3 to 5 years", "More than 5 years", "I have not started yet"],
        )
        create_step(
          name: "Have you previously completed the NPQ for Headship?",
          slug: "npqh-status",
          type: "Radio buttons",
          order: 30,
          previous_step: headship_stage,
          answers: ["Yes", "No", "I am currently completing it"],
        )

        course.set_answers!(
          answers: [
            { "name" => "Leading teaching", "next_step_id" => leadership_responsibility.id },
            { "name" => "Special educational needs co-ordinator (SENCO)", "next_step_id" => senco_status.id },
            { "name" => "Leading primary mathematics", "next_step_id" => teaching_for_mastery.id },
            { "name" => "Early headship coaching offer", "next_step_id" => headteacher_status.id },
          ],
        )

        previous_funding = create_step(
          name: "Have you previously received scholarship funding for this course?",
          slug: "previous-funding",
          type: "Radio buttons",
          order: 31,
          answers: ["Yes", "No", "I do not know"],
        )

        work_setting.update!(branch_join_step_id: course.id)
        course.update!(branch_join_step_id: previous_funding.id)

        funding = create_step(
          name: "How do you expect the course to be funded?",
          slug: "course-funding",
          type: "Radio buttons",
          order: 32,
          previous_step: previous_funding,
          answers: ["Department for Education scholarship", "My employer", "I will fund it myself", "I am not sure"],
        )
        funding.add_text!(
          text: "This demo records the answer but does not make a real funding decision.",
          text_size: "s",
        )

        provider = create_step(
          name: "Choose your training provider",
          slug: "choose-your-provider",
          type: "Radio buttons",
          order: 33,
          previous_step: funding,
          answers: ["Ambition Institute", "Education Development Trust", "Teach First", "UCL Institute of Education"],
        )

        provider_readiness = create_step(
          name: "Have you discussed this course with your chosen provider?",
          slug: "provider-check",
          type: "Radio buttons",
          order: 34,
          previous_step: provider,
          answers: ["Yes", "No", "I have already applied to them"],
        )

        share_provider = create_step(
          name: "Can we share your registration details with your provider?",
          slug: "share-provider",
          type: "Checkboxes",
          order: 35,
          previous_step: provider_readiness,
          answers: ["Yes, I agree to share my information"],
        )

        create_step(
          name: "Check your answers",
          slug: "check-answers",
          type: "Check answers",
          order: 36,
          previous_step: share_provider,
        )
      end

    private

      def create_step(name:, slug:, type:, order:, answers: [], previous_step: nil)
        type_as_param = type.underscore.parameterize.underscore
        config = answers.any? ? { type_as_param => { "answers" => answers.map { |answer| { "name" => answer } } } } : {}
        config["previous_step_id"] = previous_step.id if previous_step

        registration_journey.registration_steps.create!(name:, slug:, type:, order:, config:)
      end
    end
  end
end
