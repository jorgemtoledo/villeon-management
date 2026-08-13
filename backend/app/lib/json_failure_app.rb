# Devise's default failure app redirects to an HTML sign-in page, which makes
# no sense for an API-only app. This renders a plain JSON 401 instead, so
# every unauthenticated response (missing/invalid/expired/revoked token) has
# a single, predictable shape for the frontend to handle.
class JsonFailureApp < Devise::FailureApp
  def respond
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { error: "Não autenticado." }.to_json
  end
end
