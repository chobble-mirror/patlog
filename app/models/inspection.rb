class Inspection < ApplicationRecord
  has_one_attached :image

  validates :inspector, :serial, :description, :location, presence: true
  validates :earth_ohms, :insulation_mohms, :leakage, numericality: {greater_than: 0}
  validates :equipment_class, inclusion: {in: [1, 2]}
  validates :fuse_rating, numericality: {greater_than: 0, less_than_or_equal_to: 32}
  validate :image_size

  def self.search(query)
    where("serial LIKE ?", "%#{query}%")
  end

  private

  def image_size
    if image.attached? && image.blob.byte_size > 10.megabytes
      image.purge
      errors.add(:image, "cannot be larger than 10MB")
    end
  end
end
