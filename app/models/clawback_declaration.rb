# Internal declaration created when voiding a paid declaration
# paid declaration references clawback declaration
class ClawbackDeclaration < Declaration
  belongs_to :paid_declaration, class_name: "Declaration"

  enum :state, {
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back",
  }, suffix: true

  state_machine :state, initial: :awaiting_clawback do
    event :mark_clawed_back do
      transition %i[awaiting_clawback] => :clawed_back
    end
  end
end
