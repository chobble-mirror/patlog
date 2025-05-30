class InspectionsController < ApplicationController
  before_action :set_inspection, only: [:show, :edit, :update, :destroy, :certificate, :qr_code]
  before_action :check_inspection_owner, only: [:show, :edit, :update, :destroy]
  before_action :no_index
  skip_before_action :require_login, only: [:certificate, :qr_code]

  def index
    @inspections = current_user.inspections.order(created_at: :desc)
    @title = "Existing Inspections"

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

    params, image_error = process_image_params(inspection_params)
    @inspection = current_user.inspections.build(params)

    if image_error
      @inspection.errors.add(:image, image_error)
      render :new, status: :unprocessable_entity
    elsif @inspection.save
      if Rails.env.production?
        NtfyService.notify("new inspection by #{current_user.email}")
      end

      flash_and_redirect("created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    params, image_error = process_image_params(inspection_params)
    if image_error
      @inspection.errors.add(:image, image_error)
      render :edit, status: :unprocessable_entity
    elsif @inspection.update(params)
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

  def overdue
    @inspections = current_user.inspections.overdue.order(created_at: :desc)
    @title = "Overdue Inspections"
    render :index
  end

  def certificate
    pdf_data = PdfGeneratorService.generate_certificate(@inspection)

    @inspection.update(pdf_last_accessed_at: Time.current)

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

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
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
      flash[:danger] = "Access denied"
      redirect_to inspections_path and return
    end
  end

  def process_image_to_jpeg(image)
    require "image_processing/mini_magick"

    begin
      processed = ImageProcessing::MiniMagick
        .source(image.path)
        .resize_to_limit(1200, 1200)
        .convert("jpg")
        .saver(quality: 75)
        .call
    rescue MiniMagick::Error
      return nil
    end

    File.read(processed.path)
  end

  def create_jpeg_blob(image, filename)
    jpeg = process_image_to_jpeg(image)
    return nil unless jpeg

    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(jpeg),
      filename: filename,
      content_type: "image/jpeg"
    )
  end

  def flash_and_redirect(action)
    flash[:success] = "Inspection record #{action}"
    redirect_to (action == "deleted") ? inspections_path : @inspection
  end

  def process_image_params(params)
    image = params.delete(:image)
    return [params, nil] unless image

    filename = "#{image.original_filename.split(".")[0]}.jpg"
    if (jpeg_blob = create_jpeg_blob(image, filename))
      params[:image] = jpeg_blob.signed_id
    else
      error = "must be an image file"
    end

    [params, error]
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
