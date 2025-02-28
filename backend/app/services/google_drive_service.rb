class GoogleDriveService
  def initialize(access_token = nil)
    @service = Google::Apis::DriveV3::DriveService.new
    if access_token
      @service.authorization = initialize_authorization(access_token)
    end
  end

  def list_files(folder_path = nil)
    Rails.logger.info "Starting list_files with folder_path: #{folder_path}"
    
    begin
      query = build_query(folder_path)
      Rails.logger.info "=== Google Drive API Request ==="
      Rails.logger.info "Query: #{query}"
      Rails.logger.info "Authorization token present: #{@service.authorization.access_token ? 'Yes' : 'No'}"
      
      # APIリクエストのパラメータをログに出力
      request_params = {
        q: query,
        fields: 'files(id, name, mimeType, thumbnailLink, webViewLink, createdTime, modifiedTime)',
        spaces: 'drive',
        page_size: 100,
        order_by: 'name'
      }
      Rails.logger.info "Request parameters: #{request_params.inspect}"

      response = @service.list_files(**request_params)
      
      # レスポンスの詳細をログに出力
      Rails.logger.info "Response received"
      Rails.logger.info "Response files count: #{response.files&.length || 0}"
      if response.files&.any?
        Rails.logger.info "First file: #{response.files.first.to_h}"
      end

      Rails.logger.info "API response received: #{response.files&.length} files found"
      response.files || []
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "Authorization error: #{e.message}"
      []
    rescue Google::Apis::ClientError => e
      Rails.logger.error "Client error: #{e.message}"
      []
    rescue => e
      Rails.logger.error "Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end

  private

  def initialize_authorization(access_token)
    Rails.logger.info "=== Initializing Google Drive Authorization ==="
    Rails.logger.info "Access token present: #{access_token.present?}"
    Rails.logger.info "Client ID present: #{ENV['GOOGLE_CLIENT_ID'].present?}"
    Rails.logger.info "Client secret present: #{ENV['GOOGLE_CLIENT_SECRET'].present?}"

    scopes = [
      'https://www.googleapis.com/auth/drive.metadata.readonly',
      'https://www.googleapis.com/auth/drive.file'
    ]
    Rails.logger.info "Using scopes: #{scopes.join(', ')}"

    auth = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      access_token: access_token,
      scope: scopes
    )
    
    Rails.logger.info "Authorization initialized successfully"
    auth
  end

  def build_query(folder_path)
    base_query = if folder_path.present?
      folder_id = get_folder_id(folder_path)
      return [] unless folder_id
      "'#{folder_id}' in parents"
    else
      # ルートフォルダのみを取得
      "mimeType = 'application/vnd.google-apps.folder' and 'root' in parents"
    end

    "#{base_query} and trashed = false"
  end

  def get_folder_id(folder_path)
    if folder_path == 'root' || folder_path.blank?
      'root'
    else
      current_parent_id = 'root'
      folder_names = folder_path.split('/')

      folder_names.each do |folder_name|
        query = "'#{current_parent_id}' in parents and name = '#{folder_name}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
        response = @service.list_files(q: query, fields: 'files(id)')
        
        if response.files.empty?
          Rails.logger.error "Could not find folder: #{folder_name}"
          return nil
        end
        
        current_parent_id = response.files.first.id
      end

      current_parent_id
    end
  end
end