# frozen_string_literal: true

require "test_helper"

class Atoms::TokenGeneratorTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Token Generation Service Testing
  #
  # This test suite validates secure token generation with different formats
  # and security levels for various authentication purposes.

  def setup
    @generator = Atoms::TokenGenerator.new
  end

  # URL-safe token tests
  test "generates url safe token" do
    token = @generator.url_safe_token(32)
    assert_not_nil token
    assert token.length > 0
    assert @generator.valid_format?(token, :url_safe)
  end

  test "generates url safe tokens of specified length" do
    token = @generator.url_safe_token(16)
    # URL-safe base64 encoding can vary in length due to padding
    assert token.length >= 16
  end

  test "generates unique url safe tokens" do
    token1 = @generator.url_safe_token(32)
    token2 = @generator.url_safe_token(32)
    assert_not_equal token1, token2
  end

  # Hex token tests
  test "generates hex token" do
    token = @generator.hex_token(16)
    assert_not_nil token
    assert_equal 32, token.length # Hex encoding doubles the length
    assert @generator.valid_format?(token, :hex)
  end

  test "hex token contains only valid characters" do
    token = @generator.hex_token(16)
    assert token.match?(/\A[0-9a-f]+\z/)
  end

  # Alphanumeric token tests
  test "generates alphanumeric token" do
    token = @generator.alphanumeric_token(20)
    assert_not_nil token
    assert_equal 20, token.length
    assert @generator.valid_format?(token, :alphanumeric)
  end

  test "alphanumeric token contains only letters and numbers" do
    token = @generator.alphanumeric_token(20)
    assert token.match?(/\A[A-Za-z0-9]+\z/)
  end

  # Numeric token tests
  test "generates numeric token" do
    token = @generator.numeric_token(6)
    assert_not_nil token
    assert_equal 6, token.length
    assert @generator.valid_format?(token, :numeric)
  end

  test "numeric token contains only digits" do
    token = @generator.numeric_token(8)
    assert token.match?(/\A[0-9]+\z/)
  end

  # Specialized token tests
  test "generates password reset token" do
    token = @generator.password_reset_token
    assert_not_nil token
    assert @generator.valid_format?(token, :url_safe)
  end

  test "generates email verification token" do
    token = @generator.email_verification_token
    assert_not_nil token
    assert @generator.valid_format?(token, :url_safe)
  end

  test "generates api key" do
    key = @generator.api_key
    assert_not_nil key
    assert @generator.valid_format?(key, :alphanumeric)
  end

  test "generates session token" do
    token = @generator.session_token
    assert_not_nil token
    assert @generator.valid_format?(token, :hex)
  end

  test "generates csrf token" do
    token = @generator.csrf_token
    assert_not_nil token
    assert @generator.valid_format?(token, :url_safe)
  end

  # Unique token generation tests
  test "generates unique token with collision checking" do
    # Mock a model class for testing
    mock_model = Class.new do
      def self.exists?(conditions)
        # Simulate no existing tokens
        false
      end
    end

    token = @generator.unique_token(mock_model, :token, 32)
    assert_not_nil token
    assert @generator.valid_format?(token, :url_safe)
  end

  test "retries on collision and eventually succeeds" do
    call_count = 0
    mock_model = Class.new do
      define_singleton_method(:exists?) do |conditions|
        call_count += 1
        # Return true for first 2 calls (simulate collisions), false for 3rd
        call_count <= 2
      end
    end

    token = @generator.unique_token(mock_model, :token, 32, 5)
    assert_not_nil token
    assert_equal 3, call_count
  end

  test "raises error after max attempts" do
    mock_model = Class.new do
      def self.exists?(conditions)
        true # Always return true to simulate constant collisions
      end
    end

    assert_raises(StandardError) do
      @generator.unique_token(mock_model, :token, 32, 3)
    end
  end

  # Token with expiration tests
  test "generates token with expiration" do
    result = @generator.token_with_expiration(32, 1.hour)

    assert_not_nil result[:token]
    assert_not_nil result[:expires_at]
    assert @generator.valid_format?(result[:token], :url_safe)
    assert result[:expires_at] > Time.current
    assert result[:expires_at] <= 1.hour.from_now + 1.second
  end

  # One-time password tests
  test "generates one time password" do
    otp = @generator.one_time_password(6)
    assert_not_nil otp
    assert_equal 6, otp.length
    assert @generator.valid_format?(otp, :numeric)
  end

  test "validates otp length constraints" do
    assert_raises(ArgumentError) do
      @generator.one_time_password(3) # Too short
    end

    assert_raises(ArgumentError) do
      @generator.one_time_password(9) # Too long
    end
  end

  # Backup code tests
  test "generates backup code" do
    code = @generator.backup_code
    assert_not_nil code
    assert code.match?(/\A[A-Z0-9]{4}-[A-Z0-9]{4}\z/)
  end

  test "generates multiple backup codes" do
    codes = @generator.backup_codes(5)
    assert_equal 5, codes.length

    # All codes should be unique
    assert_equal codes.length, codes.uniq.length

    # All codes should match the format
    codes.each do |code|
      assert code.match?(/\A[A-Z0-9]{4}-[A-Z0-9]{4}\z/)
    end
  end

  # Format validation tests
  test "validates url safe format" do
    assert @generator.valid_format?("AbC123-_", :url_safe)
    assert_not @generator.valid_format?("abc+/=", :url_safe)
    assert_not @generator.valid_format?("", :url_safe)
    assert_not @generator.valid_format?(nil, :url_safe)
  end

  test "validates hex format" do
    assert @generator.valid_format?("abc123", :hex)
    assert @generator.valid_format?("ABC123", :hex)
    assert_not @generator.valid_format?("xyz123", :hex)
    assert_not @generator.valid_format?("", :hex)
  end

  test "validates alphanumeric format" do
    assert @generator.valid_format?("AbC123", :alphanumeric)
    assert_not @generator.valid_format?("abc-123", :alphanumeric)
    assert_not @generator.valid_format?("", :alphanumeric)
  end

  test "validates numeric format" do
    assert @generator.valid_format?("123456", :numeric)
    assert_not @generator.valid_format?("12a456", :numeric)
    assert_not @generator.valid_format?("", :numeric)
  end

  # Entropy tests
  test "checks sufficient entropy" do
    # Strong token with good entropy
    strong_token = @generator.url_safe_token(32)
    assert @generator.sufficient_entropy?(strong_token, 128)

    # Weak token with low entropy
    weak_token = "1111"
    assert_not @generator.sufficient_entropy?(weak_token, 128)
  end

  test "handles empty token in entropy check" do
    assert_not @generator.sufficient_entropy?("", 128)
    assert_not @generator.sufficient_entropy?(nil, 128)
  end

  # Security and randomness tests
  test "generates cryptographically random tokens" do
    tokens = 100.times.map { @generator.url_safe_token(32) }

    # All tokens should be unique
    assert_equal tokens.length, tokens.uniq.length

    # Tokens should have good distribution (no obvious patterns)
    first_chars = tokens.map { |t| t[0] }
    unique_first_chars = first_chars.uniq.length

    # Should have reasonable variety in first characters
    assert unique_first_chars > 10
  end

  # Performance tests
  test "generates tokens efficiently" do
    start_time = Time.current

    100.times do
      @generator.url_safe_token(32)
      @generator.hex_token(16)
      @generator.alphanumeric_token(20)
    end

    end_time = Time.current

    # Should complete quickly (under 100ms for 300 tokens)
    assert (end_time - start_time) < 0.1
  end

  # Edge cases
  test "handles zero length gracefully" do
    token = @generator.url_safe_token(0)
    assert_not_nil token
    # URL-safe base64 may still return some characters due to encoding
  end

  test "handles large length requests" do
    token = @generator.alphanumeric_token(1000)
    assert_equal 1000, token.length
    assert @generator.valid_format?(token, :alphanumeric)
  end
end
