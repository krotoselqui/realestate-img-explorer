class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      # 基本情報
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :username, null: false, limit: 50
      
      # プロフィール情報
      t.text :profile, limit: 1000
      
      # Google連携情報
      t.string :google_token
      t.string :google_refresh_token
      t.string :google_drive_folder_id
      t.string :google_email

      t.timestamps
    end

    # インデックスと制約の追加
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
    add_index :users, :google_email
  end
end
