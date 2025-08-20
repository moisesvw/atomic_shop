# frozen_string_literal: true

class PasswordUpdateForm
  # 📝 Password Update Form Object
  #
  # This form object encapsulates password update data and validation for
  # password reset workflows, ensuring secure password changes.

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Form attributes
  attribute :token, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  # Validations
  validates :token, presence: true
  validates :password, presence: true, length: { minimum: 8 }
  validates :password_confirmation, presence: true
  validate :passwords_match

  # Security: Don't expose sensitive data in inspect
  def inspect
    "#<#{self.class.name} token=#{token.present? ? '[PRESENT]' : '[BLANK]'}>"
  end

  private

  def passwords_match
    return unless password.present? && password_confirmation.present?
    
    errors.add(:password_confirmation, "doesn't match password") if password != password_confirmation
  end
end
