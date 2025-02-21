require 'google/apis/drive_v3'
require 'googleauth'

module GoogleDriveConfig
  class << self
    def drive_service
      @drive_service ||= Google::Apis::DriveV3::DriveService.new.tap do |service|
        service.authorization = authorize
      end
    end

    private

    def authorize
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(ENV['GOOGLE_CLOUD_CREDENTIALS']),
        scope: Google::Apis::DriveV3::AUTH_DRIVE
      )
    end
  end
end