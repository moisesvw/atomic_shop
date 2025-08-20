# frozen_string_literal: true

# ⚛️ Atom: PasswordFieldComponent
# 
# A specialized form field component for password inputs with enhanced security
# features and user experience improvements.
#
# Features:
# - Password visibility toggle
# - Password strength indicator
# - Security recommendations
# - Accessibility support
# - Consistent styling with other form fields
#
# Usage:
#   <%= render(Atoms::PasswordFieldComponent.new(
#     name: "password",
#     label: "Password",
#     value: "",
#     error: @user.errors[:password].first,
#     show_strength: true,
#     show_requirements: true
#   )) %>

class Atoms::PasswordFieldComponent < ViewComponent::Base
  attr_reader :name, :label, :value, :error, :required, :disabled, :classes,
              :show_strength, :show_requirements, :show_toggle, :autocomplete

  def initialize(
    name:,
    label: "Password",
    value: nil,
    error: nil,
    required: true,
    disabled: false,
    classes: "",
    show_strength: false,
    show_requirements: false,
    show_toggle: true,
    autocomplete: "current-password"
  )
    @name = name
    @label = label
    @value = value
    @error = error
    @required = required
    @disabled = disabled
    @classes = classes
    @show_strength = show_strength
    @show_requirements = show_requirements
    @show_toggle = show_toggle
    @autocomplete = autocomplete
  end

  private

  def field_id
    "field_#{name.to_s.gsub(/[\[\]]/, '_').gsub(/__+/, '_').chomp('_')}"
  end

  def toggle_id
    "#{field_id}_toggle"
  end

  def strength_id
    "#{field_id}_strength"
  end

  def requirements_id
    "#{field_id}_requirements"
  end

  def field_classes
    base_classes = %w[
      block w-full px-3 py-2 border rounded-md shadow-sm
      focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
      disabled:bg-gray-50 disabled:text-gray-500 disabled:cursor-not-allowed
      transition-colors duration-200
    ]

    # Add padding for toggle button if shown
    base_classes << "pr-10" if show_toggle

    state_classes = if has_error?
      %w[border-red-300 text-red-900 placeholder-red-300 focus:ring-red-500 focus:border-red-500]
    else
      %w[border-gray-300 text-gray-900 placeholder-gray-400]
    end

    (base_classes + state_classes + classes.split).join(" ")
  end

  def label_classes
    base_classes = %w[block text-sm font-medium mb-1]
    
    color_classes = if has_error?
      %w[text-red-700]
    else
      %w[text-gray-700]
    end

    (base_classes + color_classes).join(" ")
  end

  def error_classes
    %w[mt-1 text-sm text-red-600].join(" ")
  end

  def has_error?
    error.present?
  end

  def input_attributes
    attributes = {
      id: field_id,
      name: name,
      type: "password",
      value: value,
      placeholder: label,
      class: field_classes,
      required: required,
      disabled: disabled,
      autocomplete: autocomplete
    }

    attributes[:"aria-invalid"] = "true" if has_error?
    attributes[:"aria-describedby"] = describedby_ids if describedby_ids.present?

    attributes
  end

  def describedby_ids
    ids = []
    ids << "#{field_id}_error" if has_error?
    ids << strength_id if show_strength
    ids << requirements_id if show_requirements
    ids.join(" ") if ids.any?
  end

  def password_requirements
    [
      "At least 8 characters long",
      "Contains uppercase letter (A-Z)",
      "Contains lowercase letter (a-z)",
      "Contains number (0-9)"
    ]
  end

  def toggle_button_classes
    %w[
      absolute inset-y-0 right-0 pr-3 flex items-center
      text-gray-400 hover:text-gray-600 focus:text-gray-600
      cursor-pointer transition-colors duration-200
    ].join(" ")
  end
end
