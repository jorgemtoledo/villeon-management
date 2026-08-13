module JwtHelper
  # Mints a valid token for `user` without going through the HTTP login flow —
  # standard devise-jwt technique for request specs.
  def jwt_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  # Builds a token with the same secret/claims shape but an already-past exp,
  # to test expiration deterministically without traveling in time.
  def expired_jwt_for(user)
    payload = {
      "sub" => user.id.to_s,
      "scp" => "user",
      "aud" => nil,
      "jti" => user.jti,
      "exp" => 1.hour.ago.to_i
    }
    JWT.encode(payload, Warden::JWTAuth.config.secret, "HS256")
  end
end

RSpec.configure do |config|
  config.include JwtHelper, type: :request
end
