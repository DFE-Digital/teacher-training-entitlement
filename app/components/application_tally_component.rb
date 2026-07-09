class ApplicationTallyComponent < BaseComponent
  attr_reader :applications, :dimension, :dimension_header

  def initialize(applications, dimension, dimension_header: nil)
    @applications = applications
    @dimension = dimension
    @dimension_header = dimension_header || dimension.to_s.titleize
  end

  def rows
    applications.joins(joins_for_dimension).group(column).count.sort
  end

  def total_row
    rows.sum { |_, count| count }
  end

private

  def column
    "#{dimension.to_s.pluralize}.name"
  end

  def joins_for_dimension
    return { cohort: :course } if dimension == :course

    dimension
  end
end
