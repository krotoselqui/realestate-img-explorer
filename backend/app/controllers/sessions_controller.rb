class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:success] = "ログインしました"
      redirect_to dashboard_path
    else
      flash.now[:error] = "メールアドレスまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    flash[:success] = "ログアウトしました"
    redirect_to login_path, status: :see_other
  end
end