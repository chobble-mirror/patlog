module ApplicationHelper
  def display_image(image, size, options = {})
    return unless image.attached?

    variant = case size
    when :thumbnail
      ImageProcessorService.process(image, 200)
    when :medium
      ImageProcessorService.process(image, 800)
    when :large
      ImageProcessorService.process(image)
    else
      ImageProcessorService.process(image)
    end

    image_tag url_for(variant), options
  end
end
