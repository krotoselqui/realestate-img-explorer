class GoogleDriveService
  ROOT_FOLDER_NAME = 'REALESTATE_IMG_DATA'

  def initialize(access_token = nil)
    @service = Google::Apis::DriveV3::DriveService.new
    if access_token
      @service.authorization = initialize_authorization(access_token)
    end
  end

  def find_root_folder
    Rails.logger.info "\n=== Finding Root Folder ==="
    query = "name = '#{ROOT_FOLDER_NAME}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
    
    response = @service.list_files(
      q: query,
      fields: 'files(id, name, webViewLink)',
      spaces: 'drive'
    )

    if response.files&.any?
      folder = response.files.first
      Rails.logger.info "Root folder found:"
      Rails.logger.info "  - ID: #{folder.id}"
      Rails.logger.info "  - Name: #{folder.name}"
      Rails.logger.info "  - Link: #{folder.web_view_link}"
      folder
    else
      Rails.logger.info "Root folder not found"
      nil
    end
  end

  def create_root_folder
    Rails.logger.info "\n=== Creating Root Folder ==="

    # 既存のフォルダを確認
    existing_folder = find_root_folder
    if existing_folder
      Rails.logger.info "Root folder already exists"
      return existing_folder.id
    end

    # フォルダを作成
    Rails.logger.info "Creating new root folder: #{ROOT_FOLDER_NAME}"
    file_metadata = {
      name: ROOT_FOLDER_NAME,
      mime_type: 'application/vnd.google-apps.folder'
    }

    file = @service.create_file(
      file_metadata,
      fields: 'id, name, mimeType, webViewLink'
    )

    Rails.logger.info "Created folder:"
    Rails.logger.info "  - ID: #{file.id}"
    Rails.logger.info "  - Name: #{file.name}"
    Rails.logger.info "  - Link: #{file.web_view_link}"

    file.id
  end

  def create_folder(name, parent_id = nil)
    file_metadata = {
      name: name,
      mime_type: 'application/vnd.google-apps.folder'
    }
    file_metadata.merge!(parents: [parent_id]) if parent_id

    file = @service.create_file(
      file_metadata,
      fields: 'id, name, mimeType, webViewLink'
    )

    Rails.logger.info "Created folder: #{file.name} (#{file.id})"
    file.id
  end

  def list_files(folder_path = nil)
    Rails.logger.info "\n=== Starting Google Drive list_files ==="
    Rails.logger.info "Parameters:"
    Rails.logger.info "  - Folder path: #{folder_path}"
    
    auth_info = @service.authorization
    Rails.logger.info "\nAuthorization Details:"
    Rails.logger.info "  - Access token present: #{auth_info.access_token ? 'Yes' : 'No'}"
    Rails.logger.info "  - Token preview: #{auth_info.access_token ? auth_info.access_token[0..10] + '...' : 'N/A'}"
    Rails.logger.info "  - Token type: #{auth_info.token_credential_uri}"
    Rails.logger.info "  - Scopes: #{auth_info.scope&.join(', ')}"
    
    begin
      # ルートフォルダの確認または作成
      root_folder_id = ensure_root_folder
      Rails.logger.info "\nRoot Folder:"
      Rails.logger.info "  - ID: #{root_folder_id}"
      Rails.logger.info "  - Name: #{ROOT_FOLDER_NAME}"

      # フォルダパスが指定されていない場合は、ルートフォルダ内を検索
      query = if folder_path.present?
        build_query(folder_path)
      else
        "'#{root_folder_id}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
      end
      Rails.logger.info "\nAPI Request Details:"
      Rails.logger.info "  - Base query: #{query}"
      
      request_params = {
        q: query,
        fields: 'files(id, name, mimeType, thumbnailLink, webViewLink, createdTime, modifiedTime, shared, ownedByMe, owners, permissions, capabilities)',
        spaces: 'drive',
        page_size: 1000,
        order_by: 'name desc',
        include_items_from_all_drives: true,
        supports_all_drives: true,
        corpora: 'user,drive'
      }
      Rails.logger.info "\nRequest Parameters:"
      request_params.each do |key, value|
        Rails.logger.info "  - #{key}: #{value}"
      end

      Rails.logger.info "\nExecuting API Request..."
      response = @service.list_files(**request_params)
      
      Rails.logger.info "\nResponse Analysis:"
      Rails.logger.info "  - Total files found: #{response.files&.length || 0}"
      
      if response.files&.any?
        sample_file = response.files.first
        Rails.logger.info "\nSample File Analysis:"
        Rails.logger.info "  - Basic Info:"
        Rails.logger.info "    * ID: #{sample_file.id}"
        Rails.logger.info "    * Name: #{sample_file.name}"
        Rails.logger.info "    * Type: #{sample_file.mime_type}"
        Rails.logger.info "  - Access Info:"
        Rails.logger.info "    * Shared: #{sample_file.shared}"
        Rails.logger.info "    * Owned by me: #{sample_file.owned_by_me}"
        Rails.logger.info "    * Capabilities: #{sample_file.capabilities&.to_h}"
        Rails.logger.info "  - Timestamps:"
        Rails.logger.info "    * Created: #{sample_file.created_time}"
        Rails.logger.info "    * Modified: #{sample_file.modified_time}"
        Rails.logger.info "  - Links:"
        Rails.logger.info "    * Web view: #{sample_file.web_view_link}"
        Rails.logger.info "    * Thumbnail: #{sample_file.thumbnail_link}"
      end

      folder_count = response.files&.count { |f| f.mime_type == 'application/vnd.google-apps.folder' } || 0
      Rails.logger.info "\nFolder Analysis:"
      Rails.logger.info "  - Total folders: #{folder_count}"
      Rails.logger.info "  - Folder ratio: #{((folder_count.to_f / (response.files&.length || 1)) * 100).round(2)}%"

      Rails.logger.info "\n=== Successfully completed Google Drive list_files ==="
      response.files || []

    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "\nAuthorization Error:"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Token status: #{@service.authorization.access_token ? 'Present' : 'Missing'}"
      raise e
    rescue Google::Apis::ClientError => e
      Rails.logger.error "\nClient Error:"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Response body: #{e.body}" if e.respond_to?(:body)
      raise e
    rescue => e
      Rails.logger.error "\nUnexpected Error:"
      Rails.logger.error "  - Class: #{e.class}"
      Rails.logger.error "  - Message: #{e.message}"
      Rails.logger.error "  - Backtrace:\n#{e.backtrace.join("\n")}"
      raise e
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
    if folder_path.present?
      folder_id = get_folder_id(folder_path)
      return [] unless folder_id
      "'#{folder_id}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
    else
      # root_folder_idはlist_filesメソッドで設定済み
      "'#{root_folder_id}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
    end
  end

  def get_folder_id(folder_path)
    return ensure_root_folder if folder_path == ROOT_FOLDER_NAME

    root_id = ensure_root_folder
    current_parent_id = root_id
    
    folder_names = folder_path.split('/')
    folder_names.each do |folder_name|
      query = "'#{current_parent_id}' in parents and name = '#{folder_name}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
      response = @service.list_files(q: query, fields: 'files(id, name)')
      
      if response.files.empty?
        Rails.logger.info "Creating new folder: #{folder_name} in #{current_parent_id}"
        current_parent_id = create_folder(folder_name, current_parent_id)
      else
        current_parent_id = response.files.first.id
      end
    end

    current_parent_id
  end
end