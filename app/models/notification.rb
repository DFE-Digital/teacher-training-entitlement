class Notification < ApplicationEvent
  def recipient=(value)
    metadata["recipient"] = value
  end

  def cohort_id=(value)
    metadata["cohort_id"] = value if value
  end
end
