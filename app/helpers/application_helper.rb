module ApplicationHelper
  def flash_class(type)
    case type.to_s
    when 'notice'
      'bg-green-100 border border-green-400 text-green-700'
    when 'alert'
      'bg-red-100 border border-red-400 text-red-700'
    when 'warning'
      'bg-yellow-100 border border-yellow-400 text-yellow-700'
    else
      'bg-blue-100 border border-blue-400 text-blue-700'
    end
  end

  def page_title(title = nil)
    if title
      content_for(:title, "#{title} | Atomic Shop")
    else
      "Atomic Shop - E-commerce with Atomic Design"
    end
  end
end
