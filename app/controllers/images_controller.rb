class ImagesController < ApplicationController
  before_action :require_admin

  def all
    @images = ActiveStorage::Attachment.where(record_type: "Inspection", name: "image")
  end

  def orphaned
    @images = ActiveStorage::Blob.left_joins(:attachments).where(active_storage_attachments: {id: nil})
  end
end
