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

部署腳本會自動安裝 Docker 相關工具、將專案部署至 `/usr/local/app`、下載大型檔案、Build Docker Image 並啟動所有 Container。

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

> `/usr/local/app` 為本專案固定的 Docker 部署目錄。

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

因此實際部署時，專案相關檔案必須存在：

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
2. 更新 Ubuntu Package List
3. 安裝 Docker
4. 安裝 Docker Compose V2
5. 安裝 Docker Buildx
6. 安裝 MEGA Tools
7. 啟動 Docker Service
8. 檢查 Docker Daemon
9. 停止 `/usr/local/app` 目前正在執行的舊版 Container
10. 建立 `/usr/local/app`
11. 將 GitHub 專案檔案部署至 `/usr/local/app`
12. 保留既有 MySQL `mysql/data`
13. 更新 MySQL 設定與初始化檔案
14. 更新 Nginx 設定與靜態檔案
15. 下載 `jdk17.tar.gz`
16. 下載 `myWeb.jar`
17. Pull `nginx:1.28.0`
18. Pull `mysql:8`
19. 驗證 Docker Compose 設定
20. Build Docker Image
21. 啟動所有 Container
22. 顯示 Container 狀態
23. 顯示 Linux IP
24. 顯示 MySQL 連線資訊

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

正常情況下不需要手動下載。

部署腳本會自動下載至：

```text
/usr/local/app
```

如果檔案已存在：

```text
/usr/local/app/jdk17.tar.gz
/usr/local/app/myWeb.jar
```

部署腳本會自動跳過下載。

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

部署完成後，Docker Compose 的操作請在：

```text
/usr/local/app
```

執行。

進入部署目錄：

```bash
cd /usr/local/app
```

## 啟動專案

```bash
sudo docker compose up -d
```

## 重新 Build

```bash
sudo docker compose up -d --build
```

## 關閉專案

```bash
sudo docker compose down
```

## 查看 Container

```bash
sudo docker compose ps
```

也可以使用：

```bash
sudo docker ps
```

## 查看所有 Log

```bash
sudo docker compose logs -f
```

## 查看 Backend Log

```bash
sudo docker compose logs -f backend
```

## 查看 MySQL Log

```bash
sudo docker compose logs -f mysql
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

---

## 查看啟動失敗原因

```bash
cd /usr/local/app
sudo docker compose logs
```

---

# 專案更新

GitHub Repository 更新後，在 Git Repository 執行：

```bash
git pull
```

然後重新執行部署腳本：

```bash
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

---

# 常用指令

| 操作 | 指令 |
| --- | --- |
| 初次部署 | `sudo bash install_docker_tools.sh` |
| 進入部署目錄 | `cd /usr/local/app` |
| 啟動專案 | `sudo docker compose up -d` |
| 重新 Build | `sudo docker compose up -d --build` |
| 關閉專案 | `sudo docker compose down` |
| 查看 Container | `sudo docker compose ps` |
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

## 2026-09-25

重新整理自動部署流程。

主要修改：

- Git Repository 可 Clone 至任意位置
- `/usr/local/app` 保留為固定 Docker 部署目錄
- 部署腳本自動將專案複製至 `/usr/local/app`
- Docker Compose 保留既有 `/usr/local/app` Host Volume 設計
- 自動保留 `/usr/local/app/mysql/data`
- 自動更新 MySQL Config 與 Init
- 自動更新 Nginx Config 與 HTML
- 自動安裝 MEGA Tools
- 自動下載 `jdk17.tar.gz`
- 自動下載 `myWeb.jar`
- 大型檔案已存在時自動跳過下載
- 自動啟動 Docker Service
- 支援 WSL2 / Ubuntu Docker Service
- Docker Daemon 檢查
- Docker Compose 設定驗證
- Docker Buildx 檢查
- 自動 Pull Docker Images
- 自動 Build 專案
- 自動啟動 Container
- 自動顯示 Container 狀態
- 自動取得 Linux IP
- 顯示 MySQL 連線資訊
