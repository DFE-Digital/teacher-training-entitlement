# frozen_string_literal: true

all_courses = Course.all.to_a
all_cohorts = Cohort.all.to_a
all_schools = School.includes(:institution).limit(1000).to_a

LeadProvider.find_each do |lead_provider|
  quantity = { "review" => 4, "development" => 1 }.fetch(Rails.env, 0)

  quantity.times do
    # users with one application each
    FactoryBot.create_list(
      :application,
      5,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      lead_provider_approval_status: "pending",
      cohort: all_cohorts.sample,
    )

    user = FactoryBot.create(:user, :with_random_name)

    FactoryBot.create(
      :application,
      :accepted,
      :with_random_participant_outcome_state,
      :with_random_work_setting,
      user:,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      cohort: all_cohorts.sample,
    )

    FactoryBot.create_list(
      :application,
      1,
      :rejected,
      :with_random_participant_outcome_state,
      :with_random_work_setting,
      user:,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      cohort: all_cohorts.sample,
    )

    # # users with one accepted application each
    FactoryBot.create(
      :application,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      participant_outcome_state: "passed",
      cohort: all_cohorts.sample,
    )

    # users with one rejected application each
    FactoryBot.create_list(
      :application,
      2,
      :rejected,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      participant_outcome_state: "failed",
      cohort: all_cohorts.sample,
    )

    # users with one withdrawn application each
    FactoryBot.create_list(
      :application,
      2,
      :withdrawn,
      %i[accepted rejected].sample,
      :with_random_user,
      :with_random_work_setting,
      :with_random_participant_outcome_state,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      cohort: all_cohorts.sample,
    )

    # users with one eligible for funded place application each (cohort funding_cap true)
    FactoryBot.create(
      :application,
      :accepted,
      :eligible_for_funding,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      funded_place: Faker::Boolean.boolean(true_ratio: 0.6),
      cohort: Cohort.where(funding_cap: true).sample,
    )

    # users with one not eligible for funded place application each (cohort funding_cap true)
    FactoryBot.create(
      :application,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      funded_place: false,
      cohort: Cohort.where(funding_cap: true).sample,
    )

    # users with one funded place nil application each (cohort funding_cap false)
    FactoryBot.create(
      :application,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      eligible_for_funding: Faker::Boolean.boolean,
      lead_provider:,
      school: all_schools.sample,
      course: all_courses.sample,
      cohort: Cohort.where(funding_cap: false).sample,
    )

    # users with one deferred application each
    cohort = Cohort.where(start_year: Date.current.year - 1).first
    course = cohort.course_cohorts.first.course
    delivery_partner = lead_provider.delivery_partners.last
    next if delivery_partner.nil?

    delivery_partnership = DeliveryPartnership.find_by(delivery_partner:, lead_provider:, cohort:) || FactoryBot.create(:delivery_partnership, delivery_partner:, lead_provider:, cohort:)
    unless cohort.delivery_partnerships.include?(delivery_partnership)
      cohort.delivery_partnerships << delivery_partnership
    end

    application = FactoryBot.create(
      :application,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      :with_random_participant_outcome_state,
      lead_provider:,
      school: all_schools.sample,
      course:,
      cohort:,
    )

    application.declarations << FactoryBot.create(:declaration,
                                                  application:,
                                                  delivery_partner:,
                                                  lead_provider:,
                                                  cohort:,
                                                  course:,
                                                  declaration_date: application.schedule.applies_from + 1.day)

    application.deferred_training_status!
  end
end

course = Course.find_by!(identifier: Course::IDENTIFIERS.first.to_sym)

# Make sure some applications will appear in the In Review list
[
  { employment_type: :hospital_school },
  { employment_type: :lead_mentor_for_accredited_itt_provider },
  { employment_type: :local_authority_supply_teacher },
  { employment_type: :local_authority_virtual_school },
  { employment_type: :young_offender_institution },
  { employment_type: :other },
  { referred_by_return_to_teaching_adviser: "yes" },
].each do |application_attrs|
  FactoryBot.create(:application, :manual_review, **application_attrs.merge(course:, school: all_schools.sample))
end

Application.order(id: :desc).each.with_index do |a, i|
  a.update!(created_at: i.days.ago)
end
