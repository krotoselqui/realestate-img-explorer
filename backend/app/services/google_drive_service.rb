class GoogleDriveService
  def initialize
    @service = GoogleDriveConfig.drive_service
  end

  def list_files(folder_path)
    folder_id = get_folder_id(folder_path)
    return [] unless folder_id

    query = "'#{folder_id}' in parents and trashed = false"
    response = @service.list_files(
      q: query,
      fields: 'files(id, name, mimeType, thumbnailLink, webViewLink, createdTime, modifiedTime)',
      order_by: 'name'
    )
    
    response.files || []
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