require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.after_initialize do
    Bullet.enable                       = true
    Bullet.bullet_logger                = false
    # this is for error in admin finance statements assurance query
    Bullet.raise                        = false # Raise an error if n+1 query occurs
    Bullet.unused_eager_loading_enable  = false # Disabled due to the way our queries are structured
  end
end
