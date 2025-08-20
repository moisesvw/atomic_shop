class Molecules::ProductReviewComponent < ViewComponent::Base
  attr_reader :review, :classes

  def initialize(review:, classes: "")
    @review = review
    @classes = classes
  end

  def review_classes
    base_classes = [ "product-review" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def reviewer_name
    review.user&.full_name || "Anonymous"
  end

  def formatted_date
    review.created_at.strftime("%B %d, %Y")
  end
end
