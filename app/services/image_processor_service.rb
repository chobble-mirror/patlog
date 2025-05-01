class ImageProcessorService
  def self.process(image, max_size = 1200)
    return nil unless image.attached?

    image.variant(
      format: :jpeg,
      resize_to_limit: [max_size, max_size],
      quality: 80
    )
  end

  def self.thumbnail(image)
    return nil unless image.attached?

    image.variant(
      format: :jpeg,
      resize_to_limit: [64, 64],
      quality: 80
    )
  end
end
