# frozen_string_literal: true

# 🧬 Molecule: LoginFormComponent
# 
# A complete login form that composes atomic components (form fields, buttons)
# into a cohesive user authentication interface.
#
# Atomic Composition:
# - FormFieldComponent (email input)
# - PasswordFieldComponent (password input)
# - SubmitButtonComponent (login button)
#
# Features:
# - Email and password authentication
# - Remember me functionality
# - Forgot password link
# - Error handling and display
# - Accessibility support
# - Responsive design
#
# Usage:
#   <%= render(Molecules::LoginFormComponent.new(
#     user: @user,
#     remember_me: params[:remember_me],
#     return_to: params[:return_to]
#   )) %>

class Molecules::LoginFormComponent < ViewComponent::Base
  attr_reader :user, :remember_me, :return_to, :errors

  def initialize(user: nil, remember_me: false, return_to: nil, errors: {})
    @user = user || User.new
    @remember_me = remember_me
    @return_to = return_to
    @errors = errors
  end

  private

  def form_classes
    %w[
      space-y-6 bg-white p-6 rounded-lg shadow-md
      border border-gray-200 max-w-md mx-auto
    ].join(" ")
  end

  def header_classes
    %w[text-center mb-6].join(" ")
  end

  def title_classes
    %w[text-2xl font-bold text-gray-900 mb-2].join(" ")
  end

  def subtitle_classes
    %w[text-sm text-gray-600].join(" ")
  end

  def remember_me_classes
    %w[flex items-center justify-between].join(" ")
  end

  def checkbox_wrapper_classes
    %w[flex items-center].join(" ")
  end

  def checkbox_classes
    %w[
      h-4 w-4 text-blue-600 border-gray-300 rounded
      focus:ring-blue-500 focus:ring-2
    ].join(" ")
  end

  def checkbox_label_classes
    %w[ml-2 block text-sm text-gray-700].join(" ")
  end

  def forgot_password_classes
    %w[
      text-sm text-blue-600 hover:text-blue-500
      focus:outline-none focus:underline
      transition-colors duration-200
    ].join(" ")
  end

  def divider_classes
    %w[
      relative flex items-center justify-center
      text-sm text-gray-500 my-6
    ].join(" ")
  end

  def signup_link_classes
    %w[
      text-center text-sm text-gray-600
    ].join(" ")
  end

  def signup_link_anchor_classes
    %w[
      text-blue-600 hover:text-blue-500
      focus:outline-none focus:underline
      font-medium transition-colors duration-200
    ].join(" ")
  end

  def email_error
    errors[:email]&.first
  end

  def password_error
    errors[:password]&.first
  end

  def base_error
    errors[:base]&.first
  end
end
