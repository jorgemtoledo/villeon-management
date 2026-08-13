class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Legacy single-sector FK — superseded by `user_sectors` (Bloco 6E) for
  # real sector-based authorization, but kept as-is (unused, not backfilled)
  # per explicit decision: removing it is a separate, later migration.
  belongs_to :sector, optional: true
  has_many :stock_counts, dependent: :restrict_with_error

  has_many :user_sectors, dependent: :destroy
  has_many :sectors, through: :user_sectors

  enum :role, { admin: "admin", manager: "manager", operator: "operator" }

  validates :name, presence: true

  # Only fires when role/active are actually changing (editing name/email of
  # the last admin is fine) — blocks the update whenever it would leave zero
  # active admins, regardless of *who* triggers it (self-edit, another admin
  # editing this one, activate/deactivate) or *which* field causes it (role
  # away from admin, active flipping to false, or both at once).
  validate :must_leave_at_least_one_active_admin, on: :update

  # Devise's default active_for_authentication? always returns true — it
  # only reflects a custom "active" column if this is overridden. Without
  # this, a deactivated user could still log in and keep using an
  # already-issued JWT (Warden re-checks this on every request via
  # Devise::Hooks::Activatable, not only at login, so overriding it here is
  # enough — no need to also rotate jti on deactivate).
  def active_for_authentication?
    super && active?
  end

  # Sector-based authorization contract, consumed by Ability for the Estoque
  # module (Bloco 6G). A user's operable sectors are:
  #   - every Sector (current and future) when has_all_sector_access? is true;
  #   - exactly `sector_ids` otherwise;
  #   - none when sector_ids is empty and has_all_sector_access? is false.

  # admin is unrestricted via `manage :all` regardless of `all_sectors`
  # (Felipe never needs the flag set to already have full access) — this
  # method is the single place that combines both routes to "every sector",
  # so nothing else has to re-derive `admin? || all_sectors?` by hand.
  def has_all_sector_access?
    admin? || all_sectors?
  end

  private

  # No DB-level backstop possible here (unlike the role enum's CHECK
  # constraint) — "at least one other active admin exists" is a cross-row
  # invariant, which a single-row CHECK constraint can't express. This
  # validation is the only enforcement.
  def must_leave_at_least_one_active_admin
    return unless role_changed? || active_changed?
    return if role == "admin" && active
    return if User.where(role: "admin", active: true).where.not(id: id).exists?

    errors.add(:base, "não é possível remover o último administrador ativo do sistema")
  end
end
