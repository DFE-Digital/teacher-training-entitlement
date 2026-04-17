class SessionsController < PublicPagesController
  def destroy
    admin = current_admin
    user = current_user
    id_token = session[:id_token]

    sign_out_all_scopes

    redirect_to("/admin") and return if admin

    redirect_to(root_path) and return unless user

    redirect_to build_sign_out_uri(id_token), allow_other_host: true
  end

private

  def build_sign_out_uri(id_token)
    teacher_auth_domain_uri = URI.parse(ENV.fetch("TEACHER_AUTH_DOMAIN"))

    URI::Generic.build({
      scheme: teacher_auth_domain_uri.scheme,
      host: teacher_auth_domain_uri.host,
      port: teacher_auth_domain_uri.port,
      path: "/oauth2/logout",
      query: URI.encode_www_form({
        "id_token_hint" => id_token,
        "post_logout_redirect_uri" => post_logout_uri.to_s,
      }),
    }).to_s
  end

  def post_logout_uri
    URI.join(ENV.fetch("HOSTING_DOMAIN"), "/sign-out").to_s
  end
end
