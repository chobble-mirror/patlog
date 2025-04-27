User.create!(
  email: 'admin@example.com',
  password: 'password',
  password_confirmation: 'password',
  name: 'Admin User'
)

Inspection.create!(
  inspection_date: Date.today,
  reinspection_date: Date.today + 1.year,
  inspector: 'John Smith',
  serial: 'APP001',
  description: 'Desktop Computer',
  location: 'Office 101',
  equipment_class: 1,
  visual_pass: true,
  fuse_rating: 13,
  earth_ohms: 0.5,
  insulation_mohms: 200,
  leakage: 0.2,
  passed: true,
  comments: 'In good condition'
)
