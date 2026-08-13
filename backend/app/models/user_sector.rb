class UserSector < ApplicationRecord
  belongs_to :user
  belongs_to :sector

  validates :sector_id, uniqueness: { scope: :user_id }
end
