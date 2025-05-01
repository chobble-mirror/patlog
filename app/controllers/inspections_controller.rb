class InspectionsController < ApplicationController
  before_action :set_inspection, only: [:show, :edit, :update, :destroy, :certificate, :qr_code]
  before_action :check_inspection_owner, only: [:show, :edit, :update, :destroy]
  skip_before_action :require_login, only: [:certificate, :qr_code]

  def index
    @inspections = current_user.inspections.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.csv { send_data inspections_to_csv, filename: "inspections-#{Date.today}.csv" }
    end
  end

  def show
  end

  def new
    unless current_user.can_create_inspection?
      flash[:danger] = "You have reached your inspection limit of #{current_user.inspection_limit}. Please contact an administrator."
      redirect_to inspections_path and return
    end

    @inspection = Inspection.new
    @inspection.inspection_date = Date.today
    @inspection.reinspection_date = Date.today + 1.year
  end

  def create
    unless current_user.can_create_inspection?
      flash[:danger] = "You have reached your inspection limit of #{current_user.inspection_limit}. Please contact an administrator."
      redirect_to inspections_path and return
    end

    @inspection = current_user.inspections.build(inspection_params)
    process_attached_image(@inspection.image) if @inspection.image.attached?

    if @inspection.save
      flash_and_redirect("created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:inspection][:image].present?
      process_uploaded_image(params[:inspection][:image])
    end

    if @inspection.update(inspection_params)
      flash_and_redirect("updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inspection.destroy
    flash_and_redirect("deleted")
  end

  def search
    @inspections = params[:query].present? ?
      current_user.inspections.search(params[:query]) :
      current_user.inspections
  end

  def certificate
    pdf_data = PdfGeneratorService.generate_certificate(@inspection)

    send_data pdf_data.render,
      filename: "PAT_Certificate_#{@inspection.serial}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def qr_code
    qr_code_png = QrCodeService.generate_qr_code(@inspection)

    send_data qr_code_png,
      filename: "PAT_Certificate_QR_#{@inspection.serial}.png",
      type: "image/png",
      disposition: "inline"
  end

  private

  def inspection_params
    params.require(:inspection).permit(
      :inspection_date, :reinspection_date, :inspector, :serial,
      :description, :location, :equipment_class, :visual_pass,
      :fuse_rating, :earth_ohms, :insulation_mohms, :leakage,
      :passed, :comments, :image, :appliance_plug_check, :equipment_power,
      :load_test, :rcd_trip_time, :manufacturer
    )
  end

  def set_inspection
    @inspection = Inspection.find_by(id: params[:id].downcase)

    unless @inspection
      flash[:danger] = "Inspection record not found"
      redirect_to inspections_path and return
    end
  end

  def check_inspection_owner
    unless @inspection.user_id == current_user.id
      flash[:danger] = "You are not authorized to access this inspection record"
      redirect_to inspections_path and return
    end
  end

  def process_image_to_jpeg(image)
    require "image_processing/mini_magick"

    image_source = image.is_a?(ActionDispatch::Http::UploadedFile) ? image.path : image.download

    processed = ImageProcessing::MiniMagick
      .source(image_source)
      .resize_to_limit(1200, 1200)
      .convert("jpg")
      .call

    File.read(processed.path)
  end

  def process_attached_image(image)
    return if image.content_type == "image/jpeg"

    blob = create_jpeg_blob(image, "#{image.filename.base}.jpg")
    image.purge
    image.attach(blob)
  end

  def process_uploaded_image(image)
    return if image.content_type == "image/jpeg"

    blob = create_jpeg_blob(image, "#{image.original_filename.split(".")[0]}.jpg")
    @inspection.image.attach(blob)
    params[:inspection].delete(:image)
  end

  def create_jpeg_blob(image, filename)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(process_image_to_jpeg(image)),
      filename: filename,
      content_type: "image/jpeg"
    )
  end

  def flash_and_redirect(action)
    flash[:success] = "Inspection record #{action}"
    redirect_to (action == "deleted") ? inspections_path : @inspection
  end

  def inspections_to_csv
    attributes = %w[id serial inspection_date reinspection_date inspector description location equipment_class
      visual_pass fuse_rating earth_ohms insulation_mohms leakage passed comments
      appliance_plug_check equipment_power load_test rcd_trip_time manufacturer]

    CSV.generate(headers: true) do |csv|
      headers = attributes + ["image_url"]
      csv << headers

      current_user.inspections.order(created_at: :desc).each do |inspection|
        row = attributes.map { |attr| inspection.send(attr) }

        # Add image URL if image exists
        if inspection.image.attached?
          image_url = "#{ENV["BASE_URL"]}/rails/active_storage/blobs/redirect/#{inspection.image.blob.signed_id}/#{inspection.image.blob.filename}"
          row << image_url
        else
          row << nil
        end

        csv << row
      end
    end
  end
end
