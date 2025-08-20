# frozen_string_literal: true

class PasswordResetRequestForm
  # 📝 Password Reset Request Form Object
  #
  # This form object encapsulates password reset request data and validation,
  # providing a clean interface for initiating password recovery workflows.

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Form attributes
  attribute :email, :string

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Clean email input
  def email=(value)
    super(value&.strip&.downcase)
  end

  # Security: Don't expose sensitive data in inspect
  def inspect
    "#<#{self.class.name} email=#{email.inspect}>"
  end
end
