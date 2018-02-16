class User < ApplicationRecord
  has_many :stamps, foreign_key: :creator_id
  has_many :votes
  has_many :domains, foreign_key: :creator_id

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  def voting_power
    reputation <= 0 ? 0 : Math.log10(reputation).to_i + 1
  end
end
