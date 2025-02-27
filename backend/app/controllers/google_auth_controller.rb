class GoogleAuthController < ApplicationController
  def new
    if params[:start_auth]
      # Google OAuthの認証URLを生成
      client = Google::Apis::DriveV3::DriveService.new
      client.authorization = google_oauth_client
      auth_url = client.authorization.authorization_uri.to_s
      redirect_to auth_url, allow_other_host: true
    end
    # 認証ページを表示
  end

  def callback
    client = google_oauth_client
    client.code = params[:code]
    client.fetch_access_token!

    # アクセストークンをセッションに保存
    session[:google_access_token] = client.access_token
    session[:google_refresh_token] = client.refresh_token

    # ユーザー情報を更新
    current_user.update(
      google_token: client.access_token,
      google_refresh_token: client.refresh_token
    )

    redirect_to dashboard_path, notice: 'Googleドライブとの連携が完了しました'
  rescue OAuth2::Error => e
    redirect_to dashboard_path, alert: 'Googleドライブとの連携に失敗しました'
  end

  private

  def google_oauth_client
    client_id = ENV['GOOGLE_CLIENT_ID']
    client_secret = ENV['GOOGLE_CLIENT_SECRET']
    redirect_uri = ENV['GOOGLE_OAUTH_REDIRECT_URI']

    client = Signet::OAuth2::Client.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      scope: [
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive.metadata.readonly'
      ],
      additional_parameters: {
        'access_type' => 'offline',
        'prompt' => 'consent'
      }
    )
  end
end