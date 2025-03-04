#!/bin/bash
set -e

cd /rails

# 古いPIDファイルを削除
rm -f /rails/tmp/pids/server.pid

# 必要なディレクトリの作成
mkdir -p /rails/app/assets/builds
mkdir -p /rails/tmp/cache
mkdir -p /rails/public/assets

# 古いPIDファイルを削除
rm -f /rails/tmp/pids/server.pid

cd /rails

# Node.jsの依存関係をインストール
npm install

# アプリケーションのビルド環境を設定
export RAILS_ENV=development
export NODE_ENV=development

# アセットディレクトリの準備
mkdir -p ./app/assets/builds
mkdir -p ./public/assets

# Tailwindのビルド
npm run build:css

# マイグレーションの実行
bundle exec rake db:migrate

# アセットのプリコンパイル
bundle exec rails assets:clean
bundle exec rails assets:precompile

echo 'Setup completed'

# Railsサーバーの起動
bundle exec rails server -b 0.0.0.0