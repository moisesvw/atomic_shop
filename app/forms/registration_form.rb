# frozen_string_literal: true

class RegistrationForm
  # 📝 Registration Form Object with Comprehensive Validation
  #
  # This form object encapsulates user registration data and validation logic,
  # providing a clean interface for user account creation. It demonstrates
  # form object patterns, input validation, and security considerations.

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Form attributes
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  # Validations
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :password_confirmation, presence: true
  validate :passwords_match

  # Clean input data
  def first_name=(value)
    super(value&.strip&.titleize)
  end

  def last_name=(value)
    super(value&.strip&.titleize)
  end

  def email=(value)
    super(value&.strip&.downcase)
  end

  # Full name helper
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Security: Don't expose passwords in inspect
  def inspect
    "#<#{self.class.name} first_name=#{first_name.inspect} last_name=#{last_name.inspect} email=#{email.inspect}>"
  end

  private

  def passwords_match
    return unless password.present? && password_confirmation.present?

    errors.add(:password_confirmation, "doesn't match password") if password != password_confirmation
  end
end
