class FilesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_google_auth
  def index
    folder_path = params[:folder]
    Rails.logger.info "Fetching files for path: #{folder_path}"
    Rails.logger.info "Using token: #{current_user.google_token}"

    files = google_drive_service.list_files(folder_path)
    Rails.logger.info "Retrieved #{files.length} files"

    # フォルダのみをフィルタリング
    if params[:type] == 'folder'
      files = files.select { |file| file.mime_type == 'application/vnd.google-apps.folder' }
      Rails.logger.info "Filtered to #{files.length} folders"
    end

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

  def set_working_folder
    folder_id = params[:folder_id]
    folder_name = params[:folder_name]

    if current_user.update(
      google_drive_folder_id: folder_id
    )
      render json: {
        status: 'success',
        message: 'Working folder has been set',
        folder: {
          id: folder_id,
          name: folder_name
        }
      }
    else
      render json: { error: 'Failed to set working folder' }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def check_google_auth
    unless current_user.google_token.present?
      respond_to do |format|
        format.html { redirect_to auth_google_oauth2_path }
        format.json { render json: { error: 'Google認証が必要です', redirect_to: auth_google_oauth2_path }, status: :unauthorized }
      end
    end
  end

  def google_drive_service
    @google_drive_service ||= GoogleDriveService.new(current_user.google_token)
  end
end