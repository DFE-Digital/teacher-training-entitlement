# frozen_string_literal: true

module Omniauth
  module Strategies
    class TeacherAuth < OmniAuth::Strategies::OpenIDConnect
      NAME = :teacher_auth

      option :name, NAME
      option :pkce, true
      option :discovery, true
      option :send_scope_to_token_endpoint, false

      # This is a space separated string, comma separated will fail
      # offline_access is required to get a refresh_token for users without a TRN
      option :scope, %i[email openid profile teaching_record offline_access].join(" ")
    end
  end
end
