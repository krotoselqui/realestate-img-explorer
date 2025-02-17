# realestate-img-explorer
webapp to manage real estate images by google drive

# 使用技術

- **バックエンド:** Ruby on Rails  
- **データベース:** MySQL  
- **フロントエンド:** Next.js / React  
- **デプロイ:** Docker  
- **CI:** GitHub Actions  

---

# 仕様 API・ライブラリ

- **Google Drive API**

---

# API 仕様案

### 画像一覧を取得
- **エンドポイント:**  
  `GET /files?folder=Area/SampleBuilding/101/20XX0101`  
- **説明:**  
  指定フォルダ内の画像一覧を取得  

### 画像をアップロード
- **エンドポイント:**  
  `POST /upload?folder=Area/SampleBuilding/101/20XX0101`  
- **説明:**  
  指定フォルダに画像をアップロード  

