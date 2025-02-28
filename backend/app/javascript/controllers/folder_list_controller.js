import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "status"]

  connect() {
    this.loadFolders()
  }

  async loadFolders() {
    try {
      console.log('Loading folders...');
      const response = await fetch('/files?type=folder')
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json()
      console.log('Received folder data:', data);
      
      if (data.error) {
        throw new Error(data.error);
      }
      
      if (data.files) {
        console.log(`Found ${data.files.length} folders`);
        this.renderFolders(data.files)
      } else {
        console.log('No folders found');
        this.listTarget.innerHTML = `
          <div class="text-gray-500 p-4">
            フォルダが見つかりませんでした。
          </div>
        `
      }
    } catch (error) {
      console.error('Error loading folders:', error)
      this.listTarget.innerHTML = `
        <div class="text-red-600 p-4">
          フォルダの読み込みに失敗しました: ${error.message}
          <button onclick="window.location.reload()" class="mt-2 text-sm text-blue-600 hover:text-blue-800">
            再読み込み
          </button>
        </div>
      `
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
    return `
      <div class="flex items-center space-x-2 p-2 hover:bg-gray-100 rounded-md cursor-pointer"
           data-action="click->folder-list#selectFolder"
           data-folder-id="${folder.id}">
        <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
        </svg>
        <span class="text-sm text-gray-700">${folder.name}</span>
      </div>
    `
  }

  selectFolder(event) {
    const folderId = event.currentTarget.dataset.folderId
    const folderName = event.currentTarget.querySelector('span').textContent

    // 選択されたフォルダをハイライト表示
    this.element.querySelectorAll('[data-folder-id]').forEach(el => {
      el.classList.remove('bg-indigo-50', 'text-indigo-700')
    })
    event.currentTarget.classList.add('bg-indigo-50', 'text-indigo-700')

    // ステータス表示を更新
    this.statusTarget.textContent = `選択されたフォルダ: ${folderName}`

    // 選択ボタンを有効化
    const selectButton = document.getElementById('select-folder')
    selectButton.removeAttribute('disabled')

    // フォルダ情報を保存
    this.selectedFolderId = folderId
    this.selectedFolderName = folderName
  }

  async useFolderClick() {
    if (this.selectedFolderId) {
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
        });

        const data = await response.json();
        if (data.status === 'success') {
          // 成功メッセージを表示
          this.statusTarget.innerHTML = `
            <span class="text-green-600">
              ✓ 作業フォルダを設定しました: ${this.selectedFolderName}
            </span>
          `;
          // ボタンを無効化
          document.getElementById('select-folder').setAttribute('disabled', 'disabled');
        } else {
          throw new Error(data.error || 'Failed to set working folder');
        }
      } catch (error) {
        this.statusTarget.innerHTML = `
          <span class="text-red-600">
            エラー: ${error.message}
          </span>
        `;
      }
    }
  }
}