class Atoms::ButtonComponent < ViewComponent::Base
  attr_reader :label, :type, :disabled, :icon, :size, :data_attributes, :classes

  def initialize(label:, type: :primary, disabled: false, icon: nil, size: :medium, classes: "", data: {})
    @label = label
    @type = type
    @disabled = disabled
    @icon = icon
    @size = size
    @classes = classes
    @data_attributes = data
  end

  def button_classes
    base_classes = [ "btn" ]
    base_classes << "btn-#{type}" unless type == :default
    base_classes << "btn-#{size}" unless size == :medium
    base_classes << "disabled" if disabled
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def data
    data_attributes.transform_keys { |k| "data-#{k}" }.to_h
  end
end
