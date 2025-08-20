# frozen_string_literal: true

class User < ApplicationRecord
  # 🟢 GREEN PHASE: Implement features to make tests pass

  # Constants
  MAX_FAILED_ATTEMPTS = 5
  PASSWORD_RESET_EXPIRY = 2.hours

  # Secure password with enhanced validation
  has_secure_password

  # Associations
  has_many :orders, dependent: :nullify
  has_many :reviews, dependent: :nullify
  has_many :addresses, as: :addressable, dependent: :destroy
  has_many :user_sessions, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :password, length: { minimum: 8 }, if: :password_required?
  validate :password_complexity, if: :password_required?

  # Scopes
  scope :verified, -> { where(email_verified: true) }
  scope :unverified, -> { where(email_verified: false) }
  scope :locked, -> { where.not(locked_at: nil) }

  # Callbacks
  before_create :generate_email_verification_token

  # Email verification methods
  def email_verified?
    email_verified
  end

  def verify_email!
    update!(
      email_verified: true,
      email_verified_at: Time.current,
      email_verification_token: nil,
      email_verification_sent_at: nil
    )
  end

  # Password reset methods
  def generate_password_reset_token!
    # Generate a simple token and store it directly
    token = SecureRandom.urlsafe_base64(32)
    update!(
      password_reset_token: token,
      password_reset_sent_at: Time.current
    )
  end

  def clear_password_reset_token!
    update!(
      password_reset_token: nil,
      password_reset_sent_at: nil
    )
  end

  def password_reset_expired?
    return true if password_reset_sent_at.nil?

    password_reset_sent_at < PASSWORD_RESET_EXPIRY.ago
  end

  # Account security methods
  def increment_failed_attempts!
    increment!(:failed_login_attempts)
    lock_account! if failed_login_attempts >= MAX_FAILED_ATTEMPTS
  end

  def reset_failed_attempts!
    update!(failed_login_attempts: 0)
  end

  def lock_account!
    update!(locked_at: Time.current)
  end

  def unlock_account!
    update!(
      locked_at: nil,
      failed_login_attempts: 0
    )
  end

  def locked?
    locked_at.present?
  end

  # Authentication methods
  def update_last_login!
    update!(last_login_at: Time.current)
  end

  # Utility methods
  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def generate_email_verification_token
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
    self.email_verification_sent_at = Time.current
  end

  def password_required?
    password_digest.nil? || password.present?
  end

  def password_complexity
    return unless password.present?

    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add(:password, "must include at least one uppercase letter, one lowercase letter, and one number")
    end
  end
end
