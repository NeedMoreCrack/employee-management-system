Employee Management System

Employee Management System 使用 Docker Compose 建立執行環境。

專案包含：

- Backend
- Frontend
- MySQL
- Nginx

並提供自動部署腳本：

install_docker_tools.sh

部署腳本會自動安裝 Docker 相關工具、下載專案需要的大型檔案、建立 Docker Image 並啟動整個專案。

---

測試環境

目前已於以下 Linux 環境進行測試：

Windows

Windows Subsystem for Linux 2：

WSL2
Ubuntu 22.04

macOS

macOS 使用 UTM 建立 Ubuntu VM：

Ubuntu 24.04.2 Server AMD64

---

快速部署

1. Clone 專案

使用 Git Clone：

git clone https://github.com/NeedMoreCrack/employee-management-system.git

進入專案：

cd employee-management-system

---

2. 執行部署腳本

部署腳本需要 Root 權限。

執行：

sudo bash install_docker_tools.sh

部署腳本會自動完成以下操作：

1. 檢查 Docker Compose 設定
2. 更新 Ubuntu Package List
3. 安裝 Docker
4. 安裝 Docker Compose V2
5. 安裝 Docker Buildx
6. 安裝 MEGA Tools
7. 啟動 Docker Service
8. 檢查 Docker Daemon
9. 下載 "jdk17.tar.gz"
10. 下載 "myWeb.jar"
11. Pull "nginx:1.28.0"
12. Pull "mysql:8"
13. 驗證 Docker Compose 設定
14. Build 專案
15. 啟動所有 Container
16. 顯示 Container 狀態
17. 顯示 Linux IP
18. 顯示 MySQL 連線資訊

正常情況下只需要：

git clone https://github.com/NeedMoreCrack/employee-management-system.git
cd employee-management-system
sudo bash install_docker_tools.sh

即可完成部署。

---

大型檔案

由於以下檔案較大，因此沒有直接上傳至 GitHub。

JDK 17

jdk17.tar.gz

專案 Docker Build 使用的指定 JDK 17。

Backend JAR

myWeb.jar

Backend 專案的 JAR。

正常情況下不需要手動下載。

執行：

sudo bash install_docker_tools.sh

部署腳本會透過 MEGA 自動下載。

如果檔案已經存在於專案目錄，腳本會自動跳過下載。

---

手動下載大型檔案

如果 MEGA 自動下載失敗，可以手動下載。

首先安裝 MEGA Tools：

sudo apt update
sudo apt install megatools -y

下載 JDK 17

megatools dl 'https://mega.nz/file/F4gGmBjC#TJqBitRWbdWubIB7fRTsCzLQoe0XxkYWWWCKXXc-Be4'

下載 Backend JAR

megatools dl 'https://mega.nz/file/t8AGkDjb#OV5jHhOqXnL8xsQu77aqHeMMds6HdBkiBuzCkp3C25A'

下載完成後，確認兩個檔案位於專案根目錄：

employee-management-system/
├── docker-compose.yml
├── Dockerfile
├── install_docker_tools.sh
├── jdk17.tar.gz
├── myWeb.jar
├── mysql/
├── nginx/
└── ...

---

Docker 操作

部署完成後，後續不需要再次執行安裝腳本。

請先進入專案目錄：

cd employee-management-system

啟動專案

sudo docker compose up -d

如果有修改 Dockerfile 或需要重新 Build：

sudo docker compose up -d --build

---

關閉專案

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

查看 Backend：

sudo docker compose logs -f backend

查看 MySQL：

sudo docker compose logs -f mysql

---

查看 Linux IP

可以使用：

hostname -I

或：

ip addr

例如：

172.20.10.5

即可嘗試從本機瀏覽器存取：

http://172.20.10.5

«實際 IP 會依 WSL2、UTM 或 Linux 網路設定而有所不同。»

部署腳本執行完成後，也會自動顯示目前偵測到的 Linux IP。

---

MySQL

MySQL 由 Docker Compose 建立。

目前連線設定：

設定| 值
Host| Linux IP
Port| "3307"
User| "root"
Password| "321321321"
Database| "restful"

使用 MySQL Client 連線：

mysql -h <Linux-IP> -P3307 -u root -p

例如：

mysql -h 172.20.10.5 -P3307 -u root -p

接著輸入：

321321321

---

部署成功

成功部署後會看到類似：

✔ backend                   Built
✔ Network myWeb             Created
✔ Container mysql           Started
✔ Container myweb-backend   Started
✔ Container myweb-frontend  Started

接著可以使用：

sudo docker compose ps

確認服務狀態。

---

部署腳本錯誤

如果沒有使用 Root 權限執行：

bash install_docker_tools.sh

腳本會停止並顯示：

[ERROR] This script must be run as root.

Please run:
sudo bash install_docker_tools.sh

請改用：

sudo bash install_docker_tools.sh

---

專案更新

如果 GitHub 專案有更新：

git pull

如果只有程式或 Docker 設定變更，可以重新 Build：

sudo docker compose up -d --build

查看狀態：

sudo docker compose ps

---

常用指令

操作| 指令
部署環境| "sudo bash install_docker_tools.sh"
啟動專案| "sudo docker compose up -d"
重新 Build| "sudo docker compose up -d --build"
關閉專案| "sudo docker compose down"
查看 Container| "sudo docker compose ps"
查看 Log| "sudo docker compose logs -f"
查看 Docker Image| "sudo docker images"
查看 Linux IP| "hostname -I"

---

更新紀錄

2025-07-08

新增 Docker 安裝及 Image Pull 腳本。

自動安裝：

- Docker
- Docker Compose V2
- Docker Buildx

自動 Pull：

- nginx
- MySQL

---

2026-09-24

重新整理專案部署流程。

新增：

- 自動偵測專案目錄
- 不再限制專案必須放置於 "/usr/local/app"
- 自動安裝 MEGA Tools
- 自動下載 "jdk17.tar.gz"
- 自動下載 "myWeb.jar"
- 已存在的大型檔案自動跳過下載
- 自動啟動 Docker Service
- WSL2 Docker Service 啟動相容處理
- Docker Daemon 檢查
- Docker Compose 設定驗證
- 自動 Pull Docker Images
- 自動 Build 專案
- 自動啟動 Container
- 自動顯示 Container 狀態
- 自動取得 Linux IP
- 顯示 MySQL 連線資訊
