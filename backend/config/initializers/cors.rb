# Be sure to restart your server when you modify this file.
#
# Avoid CORS issues when API is called from the frontend app (Next.js, separate origin).
# Origins are configured via ENV, never hardcoded to a public/generic domain.
#
# Read more: https://github.com/cyu/rack-cors

allowed_origins = ENV.fetch("CORS_ORIGINS", "http://localhost:3001").split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: false,
      # devise-jwt returns the token only in the Authorization response header
      # (never in the JSON body) — without exposing it, browser JS cannot read
      # it cross-origin even though the header is present on the wire.
      expose: [ "Authorization" ]
  end
end
