class User < ApplicationRecord
  has_secure_password

  has_many :orders, dependent: :nullify
  has_many :reviews, dependent: :nullify
  has_many :addresses, as: :addressable, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
