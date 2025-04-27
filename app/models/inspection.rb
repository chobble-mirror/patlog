class Inspection < ApplicationRecord
  validates :inspector, :serial, :description, :location, presence: true
  validates :earth_ohms, :insulation_mohms, :leakage, numericality: {greater_than: 0}
  validates :equipment_class, inclusion: {in: [1, 2]}
  validates :fuse_rating, numericality: {greater_than: 0, less_than_or_equal_to: 32}

  def self.search(query)
    where("serial LIKE ?", "%#{query}%")
  end
end
