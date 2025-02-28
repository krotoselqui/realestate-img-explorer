class FilesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_google_auth

  def index
    Rails.logger.info "\n=== Starting files#index ==="
    Rails.logger.info "Request details:"
    Rails.logger.info "  - User: #{current_user.email}"
    Rails.logger.info "  - Access Token: #{current_user.google_token ? current_user.google_token[0..10] + '...' : 'Missing'}"
    Rails.logger.info "  - Token Length: #{current_user.google_token&.length}"
    Rails.logger.info "  - Parameters: #{params.inspect}"

    begin
      files = google_drive_service.list_files(params[:folder])
      Rails.logger.info "API Response:"
      Rails.logger.info "  - Files count: #{files&.length || 0}"
      if files&.first
        Rails.logger.info "  - Sample file: #{files.first.to_h.slice(:id, :name, :mimeType)}"
      end

      # フォルダのみをフィルタリング
      if params[:type] == 'folder'
        files = files.select { |file| file.mime_type == 'application/vnd.google-apps.folder' }
        Rails.logger.info "  - Filtered folders count: #{files.length}"
      end

      response = {
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

      Rails.logger.info "  - Response size: #{response[:files].length} items"
      Rails.logger.info "=== Successfully completed files#index ==="

      render json: response

    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "Authorization Error:"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Token status: #{current_user.google_token ? 'Present' : 'Missing'}"
      render json: { 
        error: "認証エラーが発生しました。再度ログインしてください。",
        redirect_to: auth_google_oauth2_path
      }, status: :unauthorized

    rescue Google::Apis::ClientError => e
      Rails.logger.error "Google API Client Error:"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Body: #{e.body}"
      render json: { error: "Googleドライブへのアクセスに失敗しました: #{e.message}" }, 
             status: :bad_request

    rescue => e
      Rails.logger.error "Unexpected Error:"
      Rails.logger.error "  - Class: #{e.class}"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Backtrace:\n#{e.backtrace.join("\n")}"
      render json: { error: "予期せぬエラーが発生しました: #{e.message}" }, 
             status: :internal_server_error
    end
  end

  def set_working_folder
    folder_id = params[:folder_id]
    folder_name = params[:folder_name]

    if current_user.update(google_drive_folder_id: folder_id)
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
        format.json { 
          render json: { 
            error: 'Google認証が必要です', 
            redirect_to: auth_google_oauth2_path 
          }, status: :unauthorized 
        }
      end
    end
  end

  def google_drive_service
    @google_drive_service ||= GoogleDriveService.new(current_user.google_token)
  end
end