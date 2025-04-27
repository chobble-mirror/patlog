class ImageProcessorService
  def self.process(image)
    return nil unless image.attached?

    # Process to jpeg if not already
    if image.content_type != "image/jpeg"
      image.variant(format: :jpeg)
    end

    # Generate full-size variant - max 1200px on longest side
    image.variant(resize_to_limit: [1200, 1200])
  end

  def self.thumbnail(image)
    return nil unless image.attached?

    # Generate thumbnail - max 64px on longest side
    image.variant(format: :jpeg, resize_to_limit: [64, 64])
  end
end