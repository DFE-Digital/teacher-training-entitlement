Statement.where(state: "open").joins(:contracts).find_each do |statement|
  contract = statement.contracts.first
  next unless contract

  course_cohort = CourseCohort.where(course: contract.course).first
  next unless course_cohort

  milestone_started = course_cohort.milestones.find_by(declaration_type: "started")
  milestone_completed = course_cohort.milestones.find_by(declaration_type: "completed")
  next unless milestone_started

  delivery_partner = statement.lead_provider.delivery_partners.first
  next unless delivery_partner

  applications = Application.joins(:current_application_lead_provider)
                            .where(application_lead_providers: { lead_provider_id: statement.lead_provider_id })
                            .where(status: "accepted")
                            .limit(10)

  applications.each_with_index do |app, i|
    next if Declaration.exists?(application: app, statement: statement)

    Declaration.create!(
      application: app,
      declaration_type: "started",
      state: "eligible",
      statement: statement,
      milestone: milestone_started,
      lead_provider: statement.lead_provider,
      delivery_partner: delivery_partner,
      declaration_date: 1.month.ago,
      ecf_id: SecureRandom.uuid,
    )

    next unless i < 5 && milestone_completed

    Declaration.create!(
      application: app,
      declaration_type: "completed",
      state: "eligible",
      statement: statement,
      milestone: milestone_completed,
      lead_provider: statement.lead_provider,
      delivery_partner: delivery_partner,
      declaration_date: 1.week.ago,
      ecf_id: SecureRandom.uuid,
    )
  end
end
