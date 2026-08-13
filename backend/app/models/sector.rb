class Sector < ApplicationRecord
  # Legacy — backed by User's single `sector_id` FK, unused today (see
  # User#sector). Left as-is: still correctly blocks deleting a Sector that
  # column still points to, so it's not inconsistent, just superseded by
  # `user_sectors` below for real authorization.
  has_many :users, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error

  # A user_sector row is a permission grant, not a business record — no
  # reason to block deleting a Sector just because someone had access to it.
  has_many :user_sectors, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
