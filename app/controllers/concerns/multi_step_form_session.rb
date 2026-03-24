module MultiStepFormSession
  extend ActiveSupport::Concern

  included do
    class_attribute :_session_form_data_key, instance_writer: false
    helper_method :session_form_data
  end

  class_methods do
    def storing_form_session_as(key)
      self._session_form_data_key = key
    end
  end

  def session_form_data
    (session[current_session_key] ||= {}).with_indifferent_access
  end

  def store_session_form_data!(attrs)
    session[current_session_key] = session_form_data.merge(attrs.to_h)
  end

  def clear_session_form_data!
    session.delete(current_session_key)
  end

private

  def current_session_key
    self.class._session_form_data_key || :mutli_step_session
  end
end
