class UserSerializer
  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  # Deliberately never touches encrypted_password, jti, or
  # reset_password_token — this whitelist is the only thing that reaches
  # the API, so there's no accidental leak to guard against separately.
  def call
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      active: user.active,
      all_sectors: user.all_sectors,
      sector_ids: user.sector_ids,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  private

  attr_reader :user
end
