#!/bin/bash
set -e

cd /rails

# マイグレーションの実行
bundle exec rake db:migrate

# マイグレーションの実行
bundle exec rake db:migrate

# アセットディレクトリの作成
mkdir -p /rails/app/assets/builds
mkdir -p /rails/tmp/cache

# Node.jsの依存関係をインストール
cd /rails && npm install

# アセットのビルドとプリコンパイル
bundle exec rails assets:clean
bundle exec rails assets:precompile

echo 'Setup completed'

# Railsサーバーの起動
bundle exec rails server -b 0.0.0.0