# frozen_string_literal: true

class LoginForm
  # 📝 Login Form Object with Validation
  #
  # This form object encapsulates login form data and validation logic,
  # providing a clean interface between the controller and the authentication
  # services. It demonstrates form object patterns and input validation.

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Form attributes
  attribute :email, :string
  attribute :password, :string
  attribute :remember_me, :boolean, default: false

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 1 }

  # Clean email input
  def email=(value)
    super(value&.strip&.downcase)
  end

  # Security: Don't expose password in inspect
  def inspect
    "#<#{self.class.name} email=#{email.inspect} remember_me=#{remember_me}>"
  end
end
