require "rails_helper"

RSpec.describe "registration_journeys:create_minimal_nested_demo_journey" do
  subject(:run_task) do
    Rake::Task["registration_journeys:create_minimal_nested_demo_journey"].invoke
  end

  after do
    Rake::Task["registration_journeys:create_minimal_nested_demo_journey"].reenable
  end

  it "creates the minimal nested journey with inner and outer joins" do
    run_task

    journey = RegistrationJourney.find_by!(slug: "minimal-nested-demo")
    steps = journey.registration_steps
    drink = steps.find_by!(slug: "choose-a-drink")
    milk = steps.find_by!(slug: "coffee-milk")
    coffee_size = steps.find_by!(slug: "coffee-size")
    check_answers = steps.find_by!(slug: "check-answers")

    expect(steps.count).to eq(7)
    expect(steps.pluck(:order)).to eq((1..7).to_a)
    expect(milk.branch_join_registration_step).to eq(coffee_size)
    expect(drink.branch_join_registration_step).to eq(check_answers)
    expect(RegistrationJourneyGraph.new(journey).order_groups.map(&:size)).to eq([6, 1])
  end

  it "replaces an existing minimal nested demo" do
    existing_journey = RegistrationJourney.create!(name: "Old minimal demo", slug: "minimal-nested-demo")

    expect { run_task }.not_to change(RegistrationJourney, :count)

    expect(RegistrationJourney.find_by!(slug: "minimal-nested-demo").id).not_to eq(existing_journey.id)
  end
end
