module DateHelper
  def get_academic_year(date)
    date.year - (date.month < 9 ? 1 : 0)
  end
end
