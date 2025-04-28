class QrCodeService
  def self.generate_qr_code(inspection)
    require "rqrcode"

    # Create QR code for the certificate URL using the shorter format
    url = "#{ENV['BASE_URL']}/c/#{inspection.id}"
    
    # Create QR code with optimized options for chunkier appearance
    qrcode = RQRCode::QRCode.new(url, {
      # Use lower error correction level for fewer modules (chunkier code)
      # :l - 7% error correction (lowest, largest modules)
      # :m - 15% error correction 
      # :q - 25% error correction
      # :h - 30% error correction (highest, smallest modules)
      level: :l
    })
    
    qrcode.as_png(
      bit_depth: 1,
      border_modules: 2,           # Less border space
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 8,           # Larger modules
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 300
    ).to_blob
  end
end