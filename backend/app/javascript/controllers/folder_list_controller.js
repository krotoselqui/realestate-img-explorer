import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "status", "loading"]

  get loadingTemplate() {
    return `
      <div class="animate-pulse space-y-4">
        <div class="flex items-center space-x-2">
          <div class="w-5 h-5 bg-gray-200 rounded"></div>
          <div class="h-4 bg-gray-200 rounded w-1/3"></div>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-5 h-5 bg-gray-200 rounded"></div>
          <div class="h-4 bg-gray-200 rounded w-1/2"></div>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-5 h-5 bg-gray-200 rounded"></div>
          <div class="h-4 bg-gray-200 rounded w-1/4"></div>
        </div>
      </div>
    `
  }

  get createRootFolderTemplate() {
    return `
      <div class="text-center py-8">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">REALESTATE_IMG_DATAフォルダがありません</h3>
        <p class="mt-1 text-sm text-gray-500">
          画像ファイルを管理するためのフォルダを作成してください
        </p>
        <div class="mt-6">
          <button type="button"
            data-action="folder-list#createRootFolder"
            class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            <svg class="h-4 w-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            フォルダを作成
          </button>
        </div>
      </div>
    `
  }

  get emptyTemplate() {
    return `
      <div class="text-center py-8">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">フォルダがありません</h3>
        <p class="mt-1 text-sm text-gray-500">
          REALESTATE_IMG_DATAフォルダ内にフォルダを作成してください
        </p>
      </div>
    `
  }

  connect() {
    console.log("🔌 FolderList controller connected")
    if (!this.listTarget) {
      console.error("❌ List target not found!")
      return
    }

    this.loadFolders()
  }

  async loadFolders() {
    try {
      this.listTarget.innerHTML = this.loadingTemplate
      console.log("📂 Loading folders...")

      const response = await fetch('/files?type=folder', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        },
        credentials: 'same-origin'
      })

      console.log("📡 Response status:", response.status)

      // 認証が必要な場合のリダイレクト処理
      if (response.status === 401) {
        const data = await response.json()
        if (data.redirect_to) {
          console.log("🔄 Redirecting to auth:", data.redirect_to)
          window.location.href = data.redirect_to
          return
        }
      }

      // その他のエラー処理
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      console.log("📊 Response data:", data)

      if (data.error) {
        throw new Error(data.error)
      }

      // ルートフォルダが存在しない場合
      if (!data.root_folder) {
        console.log("📁 Root folder not found")
        this.listTarget.innerHTML = this.createRootFolderTemplate
        return
      }

      // フォルダ一覧の表示
      if (data.files && data.files.length > 0) {
        console.log("📁 Rendering folders in root folder...")
        this.renderFolders(data.files)
      } else {
        console.log("📭 No folders in root folder")
        this.listTarget.innerHTML = this.emptyTemplate
      }
    } catch (error) {
      console.error("❌ Error:", error)
      this.showError(error)
    }
  }

  renderFolders(folders) {
    const folderItems = folders.map(folder => this.renderFolderItem(folder))
    this.listTarget.innerHTML = `
      <div class="space-y-2">
        ${folderItems.join('')}
      </div>
    `
  }

  renderFolderItem(folder) {
    const isSelected = folder.id === this.selectedFolderId
    return `
      <div class="group flex items-center space-x-2 p-2 ${isSelected ? 'bg-indigo-50' : 'hover:bg-gray-100'} rounded-md cursor-pointer transition-colors duration-150"
           data-action="click->folder-list#selectFolder"
           data-folder-id="${folder.id}">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 ${isSelected ? 'text-indigo-500' : 'text-gray-400 group-hover:text-gray-500'}" 
               fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <span class="text-sm ${isSelected ? 'text-indigo-700 font-medium' : 'text-gray-700 group-hover:text-gray-900'}">
            ${folder.name}
          </span>
          <p class="text-xs text-gray-500 truncate">
            作成日: ${new Date(folder.created_at).toLocaleDateString()}
          </p>
        </div>
        ${isSelected ? `
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
        ` : ''}
      </div>
    `
  }

  showError(error) {
    // エラーの種類に応じたアイコンとメッセージを設定
    let icon, title, message, showRetry = true;

    switch (error.error_code) {
      case 'AUTH_ERROR':
        icon = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m0 0v2m0-2h2m-2 0H8m4-6V4" />`
        title = '認証エラー'
        message = 'Google Driveへのアクセス権限が必要です。再度ログインしてください。'
        break;
      case 'API_ERROR':
        icon = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />`
        title = 'アクセスエラー'
        message = error.details || 'フォルダの読み込みに失敗しました。'
        break;
      default:
        icon = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />`
        title = '読み込みエラー'
        message = error.message || '予期せぬエラーが発生しました。'
    }

    // エラーの詳細情報があれば追加
    const details = error.details ? `
      <p class="mt-1 text-sm text-gray-500">
        ${error.details}
      </p>
    ` : '';

    this.listTarget.innerHTML = `
      <div class="text-center py-8">
        <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          ${icon}
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">${title}</h3>
        <p class="mt-1 text-sm text-red-500">
          ${message}
        </p>
        ${details}
        ${showRetry ? `
          <div class="mt-6">
            <button type="button"
              data-action="folder-list#retryLoad"
              class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              <svg class="h-4 w-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              再読み込み
            </button>
          </div>
        ` : ''}
      </div>
    `

    // 認証エラーの場合は自動的にリダイレクト
    if (error.error_code === 'AUTH_ERROR' && error.redirect_to) {
      setTimeout(() => {
        window.location.href = error.redirect_to
      }, 2000)
    }
  }

  selectFolder(event) {
    const folderId = event.currentTarget.dataset.folderId
    const folderName = event.currentTarget.querySelector('span').textContent

    console.log("📂 Selected folder:", { id: folderId, name: folderName })

    // 以前の選択を解除
    this.element.querySelectorAll('[data-folder-id]').forEach(el => {
      el.classList.remove('bg-indigo-50', 'text-indigo-700')
    })

    // 新しい選択をハイライト
    event.currentTarget.classList.add('bg-indigo-50', 'text-indigo-700')

    // ステータス表示を更新
    this.statusTarget.innerHTML = `
      <span class="text-sm font-medium text-gray-900">
        選択されたフォルダ: 
        <span class="text-indigo-600">${folderName}</span>
      </span>
    `

    // 選択ボタンを有効化
    const selectButton = document.getElementById('select-folder')
    selectButton.removeAttribute('disabled')

    // フォルダ情報を保存
    this.selectedFolderId = folderId
    this.selectedFolderName = folderName
  }

  retryLoad() {
    console.log("🔄 Retrying folder load...")
    this.loadFolders()
  }

  async useFolderClick() {
    if (!this.selectedFolderId) return

    try {
      const response = await fetch('/set_working_folder', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          folder_id: this.selectedFolderId,
          folder_name: this.selectedFolderName
        })
      })

      if (!response.ok) {
        throw new Error('フォルダの設定に失敗しました')
      }

      const data = await response.json()
      this.statusTarget.innerHTML = `
        <span class="text-green-600 flex items-center">
          <svg class="h-5 w-5 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          作業フォルダを設定しました: ${this.selectedFolderName}
        </span>
      `

      // ボタンを無効化
      document.getElementById('select-folder').setAttribute('disabled', 'disabled')
    } catch (error) {
      console.error("❌ Error setting working folder:", error)
      this.statusTarget.innerHTML = `
        <span class="text-red-600 flex items-center">
          <svg class="h-5 w-5 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          エラー: ${error.message}
        </span>
      `
    }
  }

  async createRootFolder() {
    try {
      console.log("📁 Creating root folder...")
      this.listTarget.innerHTML = this.loadingTemplate

      const response = await fetch('/create_root_folder', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error('フォルダの作成に失敗しました')
      }

      const data = await response.json()
      console.log("✅ Root folder created:", data)

      this.statusTarget.innerHTML = `
        <span class="text-green-600 flex items-center">
          <svg class="h-5 w-5 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          REALESTATE_IMG_DATAフォルダを作成しました
        </span>
      `

      // 少し待ってから再読み込み
      setTimeout(() => {
        this.loadFolders()
      }, 1500)
    } catch (error) {
      console.error("❌ Error creating root folder:", error)
      this.showError({
        error_code: 'API_ERROR',
        message: error.message,
        details: 'フォルダの作成中にエラーが発生しました。'
      })
    }
  }
}