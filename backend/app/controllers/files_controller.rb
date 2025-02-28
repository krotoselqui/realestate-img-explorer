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
      Rails.logger.info "\n=== Making Google Drive API Request ==="
      Rails.logger.info "Request Details:"
      Rails.logger.info "  - User: #{current_user.email}"
      Rails.logger.info "  - Token Length: #{current_user.google_token&.length}"
      Rails.logger.info "  - Token Preview: #{current_user.google_token ? current_user.google_token[0..10] + '...' : 'Missing'}"
      Rails.logger.info "  - Folder Param: #{params[:folder]}"
      Rails.logger.info "  - Type Param: #{params[:type]}"

      files = google_drive_service.list_files(params[:folder])
      
      Rails.logger.info "\nAPI Response Details:"
      Rails.logger.info "  - Total Files: #{files&.length || 0}"
      if files&.first
        sample = files.first
        Rails.logger.info "\nSample File Details:"
        Rails.logger.info "  - ID: #{sample.id}"
        Rails.logger.info "  - Name: #{sample.name}"
        Rails.logger.info "  - Type: #{sample.mime_type}"
        Rails.logger.info "  - Created: #{sample.created_time}"
        Rails.logger.info "  - Modified: #{sample.modified_time}"
        Rails.logger.info "  - Shared: #{sample.shared}"
        Rails.logger.info "  - Web Link: #{sample.web_view_link}"
      end

      Rails.logger.info "\nFiltering Folders:"
      # フォルダのみをフィルタリング
      if params[:type] == 'folder'
        original_count = files&.length || 0
        files = files.select { |file| file.mime_type == 'application/vnd.google-apps.folder' }
        Rails.logger.info "  - Original Count: #{original_count}"
        Rails.logger.info "  - Filtered Count: #{files.length}"
        Rails.logger.info "  - Filter Rate: #{((files.length.to_f / original_count) * 100).round(2)}%"
      end

      mapped_files = files.map { |file|
        {
          id: file.id,
          name: file.name,
          type: file.mime_type,
          thumbnail_url: file.thumbnail_link,
          view_url: file.web_view_link,
          created_at: file.created_time,
          updated_at: file.modified_time,
          shared: file.shared,
          owned_by_me: file.owned_by_me
        }
      }

      Rails.logger.info "\nAPI Response Details:"
      Rails.logger.info "  - Total files: #{mapped_files.length}"
      Rails.logger.info "  - Owned files: #{mapped_files.count { |f| f[:owned_by_me] }}"
      Rails.logger.info "  - Shared files: #{mapped_files.count { |f| f[:shared] }}"
      
      if mapped_files.any?
        sample_file = mapped_files.first
        Rails.logger.info "\nSample File Details:"
        Rails.logger.info "  - Name: #{sample_file[:name]}"
        Rails.logger.info "  - Type: #{sample_file[:type]}"
        Rails.logger.info "  - Shared: #{sample_file[:shared]}"
        Rails.logger.info "  - Owned: #{sample_file[:owned_by_me]}"
      end

      Rails.logger.info "\n=== Successfully completed files#index ==="
      render json: { files: mapped_files }

    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "\n=== Google Authorization Error ==="
      Rails.logger.error "Error Details:"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Token Status: #{current_user.google_token ? 'Present' : 'Missing'}"
      Rails.logger.error "  - Token Length: #{current_user.google_token&.length}"
      Rails.logger.error "  - Token Preview: #{current_user.google_token ? current_user.google_token[0..10] + '...' : 'N/A'}"
      Rails.logger.error "  - Request Path: #{request.path}"
      Rails.logger.error "  - Request Params: #{params.inspect}"
      
      render json: {
        error: "認証エラーが発生しました。再度ログインしてください。",
        details: e.message,
        redirect_to: auth_google_oauth2_path,
        error_code: "AUTH_ERROR"
      }, status: :unauthorized

    rescue Google::Apis::ClientError => e
      Rails.logger.error "\n=== Google API Client Error ==="
      Rails.logger.error "Error Details:"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Status Code: #{e.status_code}"
      Rails.logger.error "  - Response Body: #{e.body}"
      Rails.logger.error "  - Request Headers: #{request.headers.to_h.slice('HTTP_USER_AGENT', 'HTTP_ACCEPT', 'HTTP_ACCEPT_LANGUAGE')}"
      Rails.logger.error "  - Request Path: #{request.path}"
      Rails.logger.error "  - Request Params: #{params.inspect}"
      
      error_message = case e.status_code
        when 403 then "アクセス権限がありません。フォルダの共有設定を確認してください。"
        when 404 then "フォルダが見つかりません。削除された可能性があります。"
        else "Googleドライブへのアクセスに失敗しました。"
      end

      render json: {
        error: error_message,
        details: e.message,
        status_code: e.status_code,
        error_code: "API_ERROR"
      }, status: :bad_request

    rescue => e
      Rails.logger.error "\n=== Unexpected Error ==="
      Rails.logger.error "Error Details:"
      Rails.logger.error "  - Class: #{e.class}"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Cause: #{e.cause.inspect}"
      Rails.logger.error "  - Request Method: #{request.method}"
      Rails.logger.error "  - Request Path: #{request.path}"
      Rails.logger.error "  - Request Params: #{params.inspect}"
      Rails.logger.error "  - User: #{current_user.email}"
      Rails.logger.error "  - Token Status: #{current_user.google_token ? 'Present' : 'Missing'}"
      Rails.logger.error "\nBacktrace:"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: {
        error: "予期せぬエラーが発生しました。",
        details: e.message,
        error_type: e.class.name,
        error_code: "UNEXPECTED_ERROR"
      }, status: :internal_server_error
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