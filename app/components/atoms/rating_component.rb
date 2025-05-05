class Atoms::RatingComponent < ViewComponent::Base
  attr_reader :rating, :max_rating, :size, :show_value, :classes

  def initialize(rating:, max_rating: 5, size: :medium, show_value: true, classes: "")
    @rating = rating.to_f
    @max_rating = max_rating.to_i
    @size = size
    @show_value = show_value
    @classes = classes
  end

  def rating_classes
    base_classes = [ "rating", "rating-#{size}" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def full_stars
    rating.floor
  end

  def half_star?
    (rating - rating.floor) >= 0.5
  end

  def empty_stars
    max_rating - full_stars - (half_star? ? 1 : 0)
  end

  def formatted_rating
    sprintf("%.1f", rating)
  end
end
