# Employee Management System

Employee Management System 使用 Docker Compose 建立執行環境。

專案包含：

- Backend
- Frontend
- MySQL
- Nginx

專案提供自動部署腳本：

```text
install_docker_tools.sh
```

部署腳本會自動檢查 Docker 執行環境、將專案部署至 `/usr/local/app`、準備大型檔案、檢查 Docker Image、Build Backend Image，並啟動所有 Container。

---

# 部署架構

GitHub Repository 可以 Clone 至任意位置。

例如：

```text
/home/ubuntu/employee-management-system
```

執行部署腳本後，專案會自動部署至固定位置：

```text
/usr/local/app
```

實際 Docker Compose 會從：

```text
/usr/local/app
```

執行。

部署流程：

```text
GitHub Repository
        │
        │ git clone
        ▼
~/employee-management-system
        │
        │ sudo bash install_docker_tools.sh
        ▼
/usr/local/app
        │
        ├── Dockerfile
        ├── docker-compose.yml
        ├── jdk17.tar.gz
        ├── myWeb.jar
        ├── nginx/
        └── mysql/
             ├── conf/
             ├── init/
             └── data/
        │
        ▼
docker compose up -d --build
```

> `/usr/local/app` 為本專案固定的 Docker Runtime / Deployment 目錄。

Git Repository 與實際 Deployment Directory 為不同用途：

```text
~/employee-management-system
        │
        │ Source / Git Repository
        │
        │ install_docker_tools.sh
        │
        ▼
/usr/local/app
        │
        │ Runtime / Deployment
        │
        ▼
Docker Compose
```

---

# 為什麼使用 `/usr/local/app`

本專案的 `docker-compose.yml` 使用固定的 Host Volume 路徑。

MySQL：

```yaml
volumes:
  - "/usr/local/app/mysql/conf:/etc/mysql/conf.d"
  - "/usr/local/app/mysql/data:/var/lib/mysql"
  - "/usr/local/app/mysql/init:/docker-entrypoint-initdb.d"
```

Nginx：

```yaml
volumes:
  - "/usr/local/app/nginx/conf/nginx.conf:/etc/nginx/nginx.conf"
  - "/usr/local/app/nginx/html:/usr/share/nginx/html"
```

因此實際部署時，相關 Runtime 檔案必須存在：

```text
/usr/local/app
```

部署腳本會自動處理此流程，不需要手動複製。

---

# 測試環境

目前已於以下環境進行測試。

## Windows

Windows Subsystem for Linux 2：

```text
WSL2
Ubuntu 22.04
```

## macOS

macOS 使用 UTM 建立 Ubuntu VM：

```text
Ubuntu 24.04.2 Server AMD64
```

---

# 快速部署

## 1. Clone 專案

```bash
git clone https://github.com/NeedMoreCrack/employee-management-system.git
```

進入專案：

```bash
cd employee-management-system
```

## 2. 執行部署腳本

部署腳本需要 Root 權限：

```bash
sudo bash install_docker_tools.sh
```

正常情況下只需要：

```bash
git clone https://github.com/NeedMoreCrack/employee-management-system.git
cd employee-management-system
sudo bash install_docker_tools.sh
```

即可完成部署。

---

# 部署腳本會做什麼

`install_docker_tools.sh` 會自動執行：

1. 檢查專案必要檔案
2. 檢查 Docker、Docker Compose V2、Docker Buildx、MEGA Tools
3. 僅安裝目前缺少的套件
4. 檢查 Docker Daemon
5. Docker 尚未啟動時自動啟動 Docker Service
6. 建立 `/usr/local/app`
7. 停止既有 Docker Compose 專案
8. 清理本專案可能殘留的舊 Container
9. 檢查及處理舊的 `myWeb` Docker Network
10. 將 Git Repository 的專案檔案部署至 `/usr/local/app`
11. 保留既有 MySQL `mysql/data`
12. 更新 MySQL Config 與 Init
13. 更新 Nginx Config 與 HTML
14. 檢查 `jdk17.tar.gz`
15. 檢查 `myWeb.jar`
16. 本機不存在大型檔案時才透過 MEGA 下載
17. 檢查 `nginx:1.28.0`
18. 檢查 `mysql:8`
19. Docker Image 不存在時才執行 Pull
20. 驗證 Docker Compose 設定
21. Build Backend Docker Image
22. 啟動所有 Container
23. 顯示 Container 狀態
24. 顯示 Linux IP
25. 顯示 MySQL 連線資訊

---

# 重複執行與快取機制

部署腳本可以重複執行。

為避免每次部署都重新下載相同內容，腳本會先檢查本機資源。

## Ubuntu 套件

會檢查：

```text
docker.io
docker-compose-v2
docker-buildx
megatools
```

如果全部已安裝：

```text
Skip apt update/install.
```

只有缺少套件時才會執行安裝。

---

## Docker Image

會檢查：

```text
nginx:1.28.0
mysql:8
```

如果 Image 已存在：

```text
Skip docker pull.
```

如果 Image 不存在：

```text
docker pull
```

因此重複部署時，不需要每次重新從 Docker Registry Pull 相同 Image。

> 注意：此設計以「本機存在即使用」為原則，因此不會主動檢查遠端是否有相同 Tag 的新版 Image。

如需手動更新：

```bash
sudo docker pull nginx:1.28.0
sudo docker pull mysql:8
```

---

# 部署目錄

部署完成後：

```text
/usr/local/app/
├── Dockerfile
├── docker-compose.yml
├── jdk17.tar.gz
├── myWeb.jar
├── nginx/
│   ├── conf/
│   │   └── nginx.conf
│   └── html/
└── mysql/
    ├── conf/
    ├── init/
    └── data/
```

其中：

```text
/usr/local/app/mysql/data
```

為 MySQL 的持久化資料。

重新執行部署腳本時，此目錄不會被主動刪除。

---

# 大型檔案

由於以下檔案較大，因此沒有直接上傳至 GitHub。

## JDK 17

```text
jdk17.tar.gz
```

Docker Build 使用的指定 JDK 17。

## Backend JAR

```text
myWeb.jar
```

Backend 專案的 JAR。

部署腳本會自動處理這兩個檔案。

大型檔案的取得優先順序為：

```text
/usr/local/app
        │
        │ 已存在？
        ├── Yes → 直接使用
        │
        └── No
             │
             ▼
Git Repository
        │
        │ 已存在？
        ├── Yes → Copy 至 /usr/local/app
        │
        └── No
             │
             ▼
           MEGA
             │
             ▼
         Download
```

因此如果：

```text
/usr/local/app/jdk17.tar.gz
/usr/local/app/myWeb.jar
```

已經存在且不是空檔案，部署腳本會直接使用，不會重新下載。

如果 Deployment Directory 不存在檔案，但 Git Repository 已經存在：

```text
~/employee-management-system/jdk17.tar.gz
~/employee-management-system/myWeb.jar
```

則會直接複製至：

```text
/usr/local/app
```

只有兩個位置都不存在時，才會透過 MEGA 下載。

---

# 手動下載大型檔案

如果 MEGA 自動下載失敗，可以手動處理。

安裝 MEGA Tools：

```bash
sudo apt update
sudo apt install megatools -y
```

進入部署目錄：

```bash
cd /usr/local/app
```

## 下載 JDK 17

```bash
sudo megatools dl 'https://mega.nz/file/F4gGmBjC#TJqBitRWbdWubIB7fRTsCzLQoe0XxkYWWWCKXXc-Be4'
```

## 下載 Backend JAR

```bash
sudo megatools dl 'https://mega.nz/file/t8AGkDjb#OV5jHhOqXnL8xsQu77aqHeMMds6HdBkiBuzCkp3C25A'
```

確認：

```bash
ls -lh /usr/local/app/jdk17.tar.gz
ls -lh /usr/local/app/myWeb.jar
```

---

# Docker 操作

## 重要：Docker Compose 請從 `/usr/local/app` 操作

部署腳本實際是從：

```text
/usr/local/app
```

建立 Docker Compose Project。

因此部署完成後，啟動、停止、查看狀態及 Log 時，請先：

```bash
cd /usr/local/app
```

不要在 Git Repository：

```text
~/employee-management-system
```

直接操作已部署的 Compose Project。

---

## 啟動專案

```bash
cd /usr/local/app
sudo docker compose up -d
```

## 重新 Build

```bash
cd /usr/local/app
sudo docker compose up -d --build
```

## 關閉專案

```bash
cd /usr/local/app
sudo docker compose down
```

## 查看 Container

```bash
cd /usr/local/app
sudo docker compose ps
```

也可以直接：

```bash
sudo docker ps
```

查看包含已停止的 Container：

```bash
sudo docker ps -a
```

## 查看所有 Log

```bash
cd /usr/local/app
sudo docker compose logs -f
```

## 查看 Backend Log

```bash
cd /usr/local/app
sudo docker compose logs -f backend
```

## 查看 MySQL Log

```bash
cd /usr/local/app
sudo docker compose logs -f mysql
```

---

# Docker 權限

如果使用：

```bash
docker ps
```

或：

```bash
docker compose ps
```

出現：

```text
permission denied while trying to connect to the Docker daemon socket
```

代表目前 Linux User 沒有存取 Docker Daemon Socket 的權限。

本專案文件預設使用：

```bash
sudo docker ...
```

例如：

```bash
sudo docker ps
```

以及：

```bash
sudo docker compose ps
```

Docker Compose V2 的正確指令為：

```bash
docker compose
```

而不是：

```bash
dockercompose
```

也不是舊版：

```bash
docker-compose
```

---

# 查看 Linux IP

使用：

```bash
hostname -I
```

或：

```bash
ip addr
```

例如：

```text
192.168.1.100
```

即可嘗試從瀏覽器存取：

```text
http://192.168.1.100
```

> 實際 IP 會依 WSL2、UTM、VM 或 Linux 網路環境而有所不同。

部署腳本完成後，也會自動顯示偵測到的 Linux IP。

---

# MySQL

MySQL 由 Docker Compose 建立。

目前連線設定：

| 設定 | 值 |
| --- | --- |
| Host | Linux IP |
| Port | `3307` |
| User | `root` |
| Password | `321321321` |
| Database | `restful` |

連線：

```bash
mysql -h <Linux-IP> -P3307 -u root -p
```

例如：

```bash
mysql -h 192.168.1.100 -P3307 -u root -p
```

輸入密碼：

```text
321321321
```

---

# 部署成功

成功部署後會看到類似：

```text
✔ backend                   Built
✔ Network myWeb             Created
✔ Container mysql           Started
✔ Container myweb-backend   Started
✔ Container myweb-frontend  Started
```

接著：

```bash
cd /usr/local/app
sudo docker compose ps
```

確認所有服務狀態。

預期 Container：

```text
mysql
myweb-backend
myweb-frontend
```

---

# 部署失敗排查

## Root 權限

如果直接：

```bash
bash install_docker_tools.sh
```

會顯示：

```text
[ERROR] This script must be run as root.

Please run:
sudo bash install_docker_tools.sh
```

請使用：

```bash
sudo bash install_docker_tools.sh
```

---

## Docker Daemon 權限

如果：

```bash
docker ps
```

出現：

```text
permission denied while trying to connect to the Docker daemon socket
```

改用：

```bash
sudo docker ps
```

Docker Compose：

```bash
sudo docker compose ps
```

---

## 檢查部署目錄

```bash
ls -la /usr/local/app
```

應該可以看到：

```text
Dockerfile
docker-compose.yml
jdk17.tar.gz
myWeb.jar
mysql
nginx
```

---

## 檢查大型檔案

```bash
ls -lh /usr/local/app/jdk17.tar.gz
ls -lh /usr/local/app/myWeb.jar
```

---

## 檢查 Nginx 設定

```bash
ls -l /usr/local/app/nginx/conf/nginx.conf
```

`nginx.conf` 必須是檔案。

可以進一步確認：

```bash
file /usr/local/app/nginx/conf/nginx.conf
```

---

## 驗證 Docker Compose

```bash
cd /usr/local/app
sudo docker compose config
```

---

## 查看 Container

```bash
cd /usr/local/app
sudo docker compose ps
```

或：

```bash
sudo docker ps -a
```

---

## 查看啟動失敗原因

```bash
cd /usr/local/app
sudo docker compose logs
```

---

## Container Name Conflict

如果出現：

```text
Conflict. The container name "/mysql" is already in use
```

可以先確認：

```bash
sudo docker ps -a
```

新版部署腳本會嘗試處理本專案已知的舊 Container：

```text
mysql
myweb-backend
myweb-frontend
```

如果需要手動清理：

```bash
sudo docker rm -f mysql
sudo docker rm -f myweb-backend
sudo docker rm -f myweb-frontend
```

> 執行前請先確認這些 Container 確實屬於本專案。

---

# 專案更新

GitHub Repository 更新後，先進入 Git Repository：

```bash
cd ~/employee-management-system
```

更新：

```bash
git pull
```

重新執行部署腳本：

```bash
sudo bash install_docker_tools.sh
```

完整流程：

```bash
cd ~/employee-management-system
git pull
sudo bash install_docker_tools.sh
```

腳本會將新版專案重新部署至：

```text
/usr/local/app
```

並保留：

```text
/usr/local/app/mysql/data
```

避免一般程式更新時直接刪除既有 MySQL 資料。

已存在的：

```text
jdk17.tar.gz
myWeb.jar
nginx:1.28.0
mysql:8
```

也會優先使用本機資源，減少不必要的網路下載。

---

# 常用指令

## Git Repository

| 操作 | 指令 |
| --- | --- |
| 進入 Git Repository | `cd ~/employee-management-system` |
| 更新程式 | `git pull` |
| 部署 / 重新部署 | `sudo bash install_docker_tools.sh` |

## Deployment

| 操作 | 指令 |
| --- | --- |
| 進入部署目錄 | `cd /usr/local/app` |
| 啟動專案 | `sudo docker compose up -d` |
| 重新 Build | `sudo docker compose up -d --build` |
| 關閉專案 | `sudo docker compose down` |
| 查看 Compose Container | `sudo docker compose ps` |
| 查看所有 Container | `sudo docker ps -a` |
| 查看 Log | `sudo docker compose logs -f` |
| 查看 Docker Image | `sudo docker images` |
| 查看 Linux IP | `hostname -I` |
| 驗證 Compose | `sudo docker compose config` |

---

# 更新紀錄

## 2025-07-08

新增 Docker 安裝及 Image Pull 腳本。

自動安裝：

- Docker
- Docker Compose V2
- Docker Buildx

自動 Pull：

- Nginx
- MySQL

## 2026-09-24

重新整理自動部署流程。

主要修改：

- Git Repository 可 Clone 至任意位置
- `/usr/local/app` 保留為固定 Docker Deployment Directory
- 明確區分 Git Repository 與 Runtime Deployment Directory
- 部署腳本自動將專案複製至 `/usr/local/app`
- Docker Compose 保留既有 `/usr/local/app` Host Volume 設計
- 自動保留 `/usr/local/app/mysql/data`
- 自動更新 MySQL Config 與 Init
- 自動更新 Nginx Config 與 HTML
- 自動檢查 Docker、Docker Compose V2、Docker Buildx、MEGA Tools
- 僅安裝缺少的 Ubuntu Package
- 自動檢查 Docker Daemon
- 必要時自動啟動 Docker Service
- 自動檢查 `jdk17.tar.gz`
- 自動檢查 `myWeb.jar`
- 優先使用 `/usr/local/app` 已存在的大型檔案
- 其次使用 Git Repository 已存在的大型檔案
- 本機不存在時才透過 MEGA 下載
- 自動檢查 `nginx:1.28.0`
- 自動檢查 `mysql:8`
- Docker Image 已存在時跳過 Pull
- 自動處理本專案舊 Container
- 自動檢查舊 `myWeb` Docker Network
- Docker Compose 設定驗證
- Docker Buildx 檢查
- 自動 Build Backend Image
- 自動啟動 Container
- 自動顯示 Container 狀態
- 自動取得 Linux IP
- 顯示 MySQL 連線資訊
- 補充 Docker Daemon Socket 權限說明
- Docker 日常操作統一從 `/usr/local/app` 執行
