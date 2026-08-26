require "rails_helper"

RSpec.describe "registration_journeys rake tasks" do
  describe "registration_journeys:recreate_registration_templates" do
    subject(:run_task) do
      Rake::Task["registration_journeys:recreate_registration_templates"].invoke
    end

    after do
      Rake::Task["registration_journeys:recreate_registration_templates"].reenable
    end

    it "creates the registration templates" do
      expect { run_task }.to change(RegistrationTemplate, :count).by(6)

      expect(RegistrationTemplate.order(:name).pluck(:name, :template_generating_service_class)).to contain_exactly(
        ["Demo food journey", "Registrations::StepTemplates::FoodJourneyService"],
        ["NPD Recreation", "Registrations::StepTemplates::Courses::NpdService"],
        ["NPQ inspired journey", "Registrations::StepTemplates::NpqInspiredJourneyService"],
        ["Simple NPD style registration", "Registrations::StepTemplates::Courses::NpdStyleService"],
        ["Simple food based funding eligibility", "Registrations::StepTemplates::FundingEligibility::FoodFundingTemplateService"],
        ["Simple work setting based funding eligibility", "Registrations::StepTemplates::FundingEligibility::WorkSettingFundingTemplateService"],
      )
    end

    it "updates existing templates by service class" do
      RegistrationTemplate.create!(
        name: "Old name",
        description: "Old description",
        template_generating_service_class: "Registrations::StepTemplates::FoodJourneyService",
      )

      expect { run_task }.to change(RegistrationTemplate, :count).by(5)

      template = RegistrationTemplate.find_by!(
        template_generating_service_class: "Registrations::StepTemplates::FoodJourneyService",
      )
      expect(template).to have_attributes(
        name: "Demo food journey",
        description: "Demo of creating a branched journey",
      )
    end
  end

  describe "registration_journeys:create_npq_inspired_journey" do
    subject(:run_task) do
      Rake::Task["registration_journeys:create_npq_inspired_journey"].invoke
    end

    after do
      Rake::Task["registration_journeys:create_npq_inspired_journey"].reenable
    end

    it "creates a runnable DB-driven journey with workplace and course branch groups" do
      expect { run_task }.to change(RegistrationJourney, :count).by(1)

      journey = RegistrationJourney.find_by!(slug: "npq-inspired-demo")
      steps = journey.registration_steps

      expect(steps.count).to eq(36)
      expect(steps.pluck(:order)).to eq((1..36).to_a)

      work_setting = steps.find_by!(slug: "work-setting")
      expect(work_setting.answer_data.pluck("name")).to eq([
        "A school or academy trust",
        "An early years or childcare setting",
        "Another education setting",
      ])
      expect(work_setting.answer_data.pluck("next_step_id")).to match_array(
        steps.where(slug: %w[choose-school early-years-setting other-employment]).pluck(:id),
      )

      course = steps.find_by!(slug: "choose-your-npq")
      expect(course.answer_data.pluck("next_step_id")).to match_array(
        steps.where(slug: %w[leadership-responsibility senco-role teaching-for-mastery headteacher-status]).pluck(:id),
      )

      expect(RegistrationJourneyGraph.new(journey).order_groups.map(&:size)).to eq([1, 1, 1, 12, 15, 1, 1, 1, 1, 1, 1])
    end

    it "configures a nested SENCO branch with an explicit join" do
      run_task

      journey = RegistrationJourney.find_by!(slug: "npq-inspired-demo")
      steps = journey.registration_steps
      graph = RegistrationJourneyGraph.new(journey)
      senco_status = steps.find_by!(slug: "senco-role")
      senco_start_date = steps.find_by!(slug: "senco-start-date")
      senco_readiness = steps.find_by!(slug: "senco-readiness")
      senco_responsibilities = steps.find_by!(slug: "senco-responsibilities")

      expect(senco_status.branch_join_registration_step).to eq(senco_responsibilities)
      expect(senco_status.answer_data.pluck("next_step_id")).to contain_exactly(
        senco_start_date.id,
        senco_readiness.id,
        senco_readiness.id,
      )
      expect(graph.default_next_step_for(senco_start_date)).to eq(senco_responsibilities)
      expect(graph.default_next_step_for(senco_readiness)).to eq(senco_responsibilities)
      expect(graph.branch_steps_for_answer(senco_status, "i_am_a_senco")).to eq([senco_start_date])
    end

    it "configures a nested childcare branch inside the workplace branch" do
      run_task

      journey = RegistrationJourney.find_by!(slug: "npq-inspired-demo")
      steps = journey.registration_steps
      graph = RegistrationJourneyGraph.new(journey)
      ofsted_registration = steps.find_by!(slug: "ofsted-registration")
      childcare_provider = steps.find_by!(slug: "choose-early-years-setting")
      registration_help = steps.find_by!(slug: "childcare-registration-help")
      early_years_role = steps.find_by!(slug: "early-years-role")

      expect(ofsted_registration.branch_join_registration_step).to eq(early_years_role)
      expect(graph.default_next_step_for(childcare_provider)).to eq(early_years_role)
      expect(graph.default_next_step_for(registration_help)).to eq(early_years_role)
      expect(graph.branch_steps_for_answer(ofsted_registration, "yes")).to eq([childcare_provider])
    end

    it "configures a two-level nested mathematics branch with a direct-to-join path" do
      run_task

      journey = RegistrationJourney.find_by!(slug: "npq-inspired-demo")
      steps = journey.registration_steps
      graph = RegistrationJourneyGraph.new(journey)
      teaching_for_mastery = steps.find_by!(slug: "teaching-for-mastery")
      maths_approach = steps.find_by!(slug: "maths-mastery-understanding")
      maths_preparation = steps.find_by!(slug: "maths-course-preparation")
      maths_leadership = steps.find_by!(slug: "maths-leadership-role")

      expect(teaching_for_mastery.branch_join_registration_step).to eq(maths_leadership)
      expect(maths_approach.branch_join_registration_step).to eq(maths_leadership)
      expect(teaching_for_mastery.next_registration_step_for(answer: "yes")).to eq(maths_leadership)
      expect(teaching_for_mastery.next_registration_step_for(answer: "no")).to eq(maths_approach)
      expect(graph.default_next_step_for(maths_preparation)).to eq(maths_leadership)
      expect(graph.branch_steps_for_answer(teaching_for_mastery, "no"))
        .to contain_exactly(maths_approach, maths_preparation)
      expect(graph.branch_steps_for_answer(maths_approach, "i_use_it_regularly")).to be_empty
      expect(graph.branch_steps_for_answer(maths_approach, "i_am_new_to_the_approach"))
        .to eq([maths_preparation])
    end

    it "configures the custom step" do
      run_task

      journey = RegistrationJourney.find_by!(slug: "npq-inspired-demo")

      expect(journey.registration_steps.find_by!(slug: "senco-start-date").custom_step_class_name)
        .to eq("Forms::NpqInspired::SencoStartDateStepForm")
    end

    it "replaces an existing NPQ-inspired demo journey and its steps" do
      existing_journey = RegistrationJourney.create!(
        name: "Old NPQ demo",
        slug: "npq-inspired-demo",
      )
      existing_step = existing_journey.registration_steps.create!(
        name: "Old step",
        slug: "old-step",
        type: "Radio buttons",
        order: 1,
        config: {},
      )

      expect { run_task }.not_to change(RegistrationJourney, :count)

      replacement = RegistrationJourney.find_by!(slug: "npq-inspired-demo")
      expect(replacement.id).not_to eq(existing_journey.id)
      expect(replacement.registration_steps.count).to eq(36)
      expect(RegistrationStep).not_to exist(existing_step.id)
    end
  end
end
