module ApplicationHelper
  def display_image(image, size, options = {})
    return unless image.attached?
    
    case size
    when :thumbnail
      variant = ImageProcessorService.thumbnail(image)
    when :medium
      variant = ImageProcessorService.process(image, 800)
    when :large
      variant = ImageProcessorService.process(image)
    else
      variant = ImageProcessorService.process(image)
    end
    
    image_tag url_for(variant), options
  end
end
