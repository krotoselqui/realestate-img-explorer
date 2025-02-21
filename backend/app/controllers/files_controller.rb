class FilesController < ApplicationController
  def index
    folder_path = params[:folder]
    files = google_drive_service.list_files(folder_path)

    render json: {
      files: files.map { |file|
        {
          id: file.id,
          name: file.name,
          type: file.mime_type,
          thumbnail_url: file.thumbnail_link,
          view_url: file.web_view_link,
          created_at: file.created_time,
          updated_at: file.modified_time
        }
      }
    }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def upload
    folder_path = params[:folder]
    uploaded_files = params[:files]

    if uploaded_files.blank?
      render json: { error: 'No files provided' }, status: :bad_request
      return
    end

    results = uploaded_files.map do |file|
      uploaded_file = google_drive_service.upload_file(folder_path, file)
      {
        name: file.original_filename,
        id: uploaded_file&.id,
        view_url: uploaded_file&.web_view_link,
        success: !uploaded_file.nil?
      }
    end

    render json: { files: results }
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def create_folder
    parent_path = params[:folder]
    folder_name = params[:name]

    if folder_name.blank?
      render json: { error: 'Folder name is required' }, status: :bad_request
      return
    end

    folder = google_drive_service.create_folder(parent_path, folder_name)
    
    if folder
      render json: {
        id: folder.id,
        name: folder.name
      }
    else
      render json: { error: 'Failed to create folder' }, status: :internal_server_error
    end
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def google_drive_service
    @google_drive_service ||= GoogleDriveService.new
  end
end