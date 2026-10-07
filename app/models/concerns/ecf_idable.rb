module EcfIdable
  extend ActiveSupport::Concern

  def to_param
    ecf_id
  end
end
