EmployeeManagementSystem

專案說明

此專案使用 Docker Compose 建立執行環境。

目前已測試的 Linux 環境：

- Windows Subsystem for Linux 2（WSL2）
  - Ubuntu 22.04
- macOS + UTM
  - Ubuntu 24.04.2 Server AMD64

---

必要檔案

由於以下檔案較大，因此沒有直接上傳至 GitHub，而是存放於 MEGA：

1. "jdk17.tar.gz"
   
   - 專案指定使用的 JDK 17

2. "myWeb.jar"
   
   - Backend 專案 JAR

正常情況下不需要手動下載。

"install_docker_tools.sh" 會自動安裝 "megatools"，並下載上述檔案至：

/usr/local/app

---

快速啟動

1. 下載專案

先從 GitHub Clone 此專案：

git clone <GitHub Repository URL>

進入專案目錄：

cd EmployeeManagementSystem

---

2. 將專案放置於 "/usr/local/app"

專案執行目錄為：

/usr/local/app

請將 EmployeeManagementSystem 專案內的檔案放置於：

/usr/local/app

完成後目錄結構應類似：

/usr/local/app
├── docker-compose.yml
├── install_docker_tools.sh
├── ...

«"jdk17.tar.gz" 與 "myWeb.jar" 不需要手動放入，安裝腳本會自動下載。»

---

3. 執行安裝腳本

安裝腳本必須使用 "root" 權限執行：

cd /usr/local/app
sudo bash install_docker_tools.sh

腳本會自動執行：

1. 更新 Ubuntu 套件清單
2. 安裝 Docker
3. 安裝 Docker Compose V2
4. 安裝 Docker Buildx
5. 安裝 MEGA Tools
6. 啟動 Docker Service
7. 下載 "jdk17.tar.gz"
8. 下載 "myWeb.jar"
9. Pull "nginx:1.28.0"
10. Pull "mysql:8"
11. 檢查 Docker Compose 設定
12. 執行 "docker compose up -d"

因此不需要另外手動安裝 Docker 或下載 MEGA 檔案。

---

啟動專案

如果環境已經安裝完成，之後要再次啟動專案只需要：

cd /usr/local/app
sudo docker compose up -d

啟動成功後會看到類似：

✔ backend                   Built
✔ Network myWeb             Created
✔ Container mysql           Started
✔ Container myweb-backend   Started
✔ Container myweb-frontend  Started

---

關閉專案

cd /usr/local/app
sudo docker compose down

---

查看 Container 狀態

sudo docker compose ps

也可以使用：

sudo docker ps

---

查看 Log

查看所有服務：

sudo docker compose logs -f

如果只想查看指定服務，例如 Backend：

sudo docker compose logs -f backend

---

查詢 Linux IP

可以使用：

ip addr

或：

hostname -I

例如取得：

172.20.10.5

即可在本機瀏覽器使用該 IP 存取服務。

例如：

http://172.20.10.5

«實際 IP 依 WSL2、UTM 或 Linux 網路環境而有所不同。»

---

MySQL

Docker Compose 會建立 MySQL Container。

目前設定：

設定| 值
Port| "3307"
User| "root"
Password| "321321321"
Database| "restful"

可以從 Linux 使用以下方式連線：

mysql -h <Linux-IP> -P3307 -u root -p

例如：

mysql -h 172.20.10.5 -P3307 -u root -p

接著輸入密碼：

321321321

---

手動下載 MEGA 檔案

正常情況下不需要手動執行此步驟。

如果自動下載失敗，可以先安裝 MEGA Tools：

sudo apt update
sudo apt install megatools -y

下載 JDK 17：

megatools dl 'https://mega.nz/file/F4gGmBjC#TJqBitRWbdWubIB7fRTsCzLQoe0XxkYWWWCKXXc-Be4'

下載 Backend JAR：

megatools dl 'https://mega.nz/file/t8AGkDjb#OV5jHhOqXnL8xsQu77aqHeMMds6HdBkiBuzCkp3C25A'

下載完成後，將檔案放置於：

/usr/local/app

---

安裝腳本

專案提供：

install_docker_tools.sh

執行方式：

sudo bash install_docker_tools.sh

如果不是使用 root 權限執行，腳本會直接停止：

[ERROR] This script must be run as root.

Please run:
sudo bash install_docker_tools.sh

---

常用指令

啟動：

sudo docker compose up -d

停止：

sudo docker compose down

查看狀態：

sudo docker compose ps

查看 Log：

sudo docker compose logs -f

重新 Build：

sudo docker compose up -d --build

查看 Docker Image：

sudo docker images

查看 Linux IP：

hostname -I

---

更新紀錄

2025-07-08

- 新增 Docker 安裝腳本
- 自動安裝：
  - Docker
  - Docker Compose V2
  - Docker Buildx
- 自動 Pull 專案需要的 Docker Images

2026-09-24

- 更新 "install_docker_tools.sh"
- 新增 "megatools" 自動安裝
- 新增 MEGA 必要檔案自動下載
  - "jdk17.tar.gz"
  - "myWeb.jar"
- 自動建立 "/usr/local/app"
- 自動檢查 Docker Daemon
- 改善 WSL2 / Ubuntu Docker Service 啟動方式
- 自動檢查 Docker Compose 設定
- 自動執行 "docker compose up -d"
- 啟動完成後顯示：
  - Container 狀態
  - Linux IP
  - MySQL 連線資訊
