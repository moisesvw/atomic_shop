# frozen_string_literal: true

# 🧬 Molecule: RegistrationFormComponent
# 
# A complete user registration form that composes atomic components into
# a cohesive user signup interface.
#
# Atomic Composition:
# - FormFieldComponent (name and email inputs)
# - PasswordFieldComponent (password inputs with strength indicator)
# - SubmitButtonComponent (registration button)
#
# Features:
# - User information collection (name, email)
# - Password creation with strength validation
# - Password confirmation
# - Terms of service acceptance
# - Error handling and display
# - Accessibility support
# - Responsive design
#
# Usage:
#   <%= render(Molecules::RegistrationFormComponent.new(
#     user: @user,
#     return_to: params[:return_to]
#   )) %>

class Molecules::RegistrationFormComponent < ViewComponent::Base
  attr_reader :user, :return_to

  def initialize(user: nil, return_to: nil)
    @user = user || User.new
    @return_to = return_to
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

  def name_fields_classes
    %w[grid grid-cols-2 gap-4].join(" ")
  end

  def terms_wrapper_classes
    %w[flex items-start].join(" ")
  end

  def terms_checkbox_classes
    %w[
      h-4 w-4 text-blue-600 border-gray-300 rounded
      focus:ring-blue-500 focus:ring-2 mt-1
    ].join(" ")
  end

  def terms_label_classes
    %w[ml-2 block text-sm text-gray-700].join(" ")
  end

  def terms_link_classes
    %w[
      text-blue-600 hover:text-blue-500
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

  def signin_link_classes
    %w[
      text-center text-sm text-gray-600
    ].join(" ")
  end

  def signin_link_anchor_classes
    %w[
      text-blue-600 hover:text-blue-500
      focus:outline-none focus:underline
      font-medium transition-colors duration-200
    ].join(" ")
  end

  def field_error(field)
    user.errors[field]&.first
  end
end
