class GoogleDriveService
  def initialize(access_token = nil)
    @service = Google::Apis::DriveV3::DriveService.new
    if access_token
      @service.authorization = authorization_from_token(access_token)
    end
  end

  def list_files(folder_path = nil)
    Rails.logger.info "Starting list_files with folder_path: #{folder_path}"
    
    query = if folder_path.present?
      folder_id = get_folder_id(folder_path)
      Rails.logger.info "Resolved folder_id: #{folder_id}"
      return [] unless folder_id
      "'#{folder_id}' in parents"
    else
      Rails.logger.info "Listing root level folders"
      "mimeType = 'application/vnd.google-apps.folder'"
    end

    query += " and trashed = false"
    Rails.logger.info "Final query: #{query}"

    begin
      response = @service.list_files(
        q: query,
        fields: 'files(id, name, mimeType, thumbnailLink, webViewLink, createdTime, modifiedTime)',
        order_by: 'name'
      )
      Rails.logger.info "API response received: #{response.files&.length} files found"
      response.files || []
    rescue => e
      Rails.logger.error "Drive API error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end

  private

  def authorization_from_token(access_token)
    auth = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      access_token: access_token,
      scope: [
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive.metadata.readonly'
      ]
    )
    auth
  end

  def list_files(folder_path = nil)
    Rails.logger.info "Starting list_files with folder_path: #{folder_path}"
    
    query = if folder_path.present?
      folder_id = get_folder_id(folder_path)
      Rails.logger.info "Resolved folder_id: #{folder_id}"
      return [] unless folder_id
      "'#{folder_id}' in parents"
    else
      Rails.logger.info "Listing root level folders"
      "mimeType = 'application/vnd.google-apps.folder'"
    end

    query += " and trashed = false"
    Rails.logger.info "Final query: #{query}"

    begin
      response = @service.list_files(
        q: query,
        fields: 'files(id, name, mimeType, thumbnailLink, webViewLink, createdTime, modifiedTime)',
        order_by: 'name'
      )
      Rails.logger.info "API response received: #{response.files&.length} files found"
      response.files || []
    rescue => e
      Rails.logger.error "Drive API error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end

  def upload_file(folder_path, file)
    folder_id = get_folder_id(folder_path)
    return false unless folder_id

    file_metadata = {
      name: file.original_filename,
      parents: [folder_id]
    }

    @service.create_file(
      file_metadata,
      fields: 'id, name, webViewLink',
      upload_source: file.tempfile,
      content_type: file.content_type
    )
  end

  def create_folder(parent_path, folder_name)
    parent_id = get_folder_id(parent_path)
    return false unless parent_id

    file_metadata = {
      name: folder_name,
      parents: [parent_id],
      mime_type: 'application/vnd.google-apps.folder'
    }

    @service.create_file(file_metadata, fields: 'id, name')
  end

  private

  def get_folder_id(folder_path)
    return ENV['GOOGLE_DRIVE_ROOT_FOLDER_ID'] if folder_path.blank?

    current_parent_id = ENV['GOOGLE_DRIVE_ROOT_FOLDER_ID']
    folder_names = folder_path.split('/')

    folder_names.each do |folder_name|
      query = "'#{current_parent_id}' in parents and name = '#{folder_name}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
      response = @service.list_files(q: query, fields: 'files(id)')
      return nil if response.files.empty?
      
      current_parent_id = response.files.first.id
    end

    current_parent_id
  end
end