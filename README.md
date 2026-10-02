
# Employee Management System

以 Docker Compose 部署 Employee Management System：Spring Boot 後端、由 Nginx 提供的前端靜態檔案，以及 MySQL。Git Repository 是部署來源，實際運行目錄固定為 `/usr/local/app`。

本專案已在 WSL Ubuntu（AMD64）與 Android Podroid Alpine（ARM64）進行部署測試。Podroid 可能使用獨立虛擬網路，因此 **Podroid Linux IP 不等於 Android Wi-Fi IP**；從桌機連線可使用 Repository 根目錄的 SSH Tunnel 腳本。

## 專案目錄

以下是 GitHub `main` 分支的**根目錄配置**；`connect-podroid.bat` 和 `connect-podroid.sh` 就在根目錄，**沒有 `scripts/` 資料夾**。

```text
employee-management-system/
├── .gitignore
├── Dockerfile
├── README.md
├── connect-podroid.bat       # Windows SSH Tunnel
├── connect-podroid.sh        # macOS / Linux SSH Tunnel
├── docker-compose.yml
├── install_docker_tools.sh   # 檢查環境、準備 JAR、部署 Compose
├── manage.sh                 # 互動式 Docker 管理選單
├── mysql/
│   ├── conf/                 # MySQL 設定
│   ├── init/                 # 首次初始化時使用的 SQL
│   └── data/                 # 執行時持久化資料，不應提交 Git
└── nginx/
    ├── conf/
    │   └── nginx.conf
    └── html/                 # 前端建置後的靜態檔案
```

> `mysql/data/` 為部署時使用的目錄，不代表新 Clone 下來時會包含資料庫內容。`myWeb.jar` 不必提交 Git；安裝腳本可以由 Docker Hub 的檔案載體映像提取。舊版的 `jdk17.tar.gz` 已不再需要。

## 部署架構與固定路徑

Repository 可以 Clone 到任意目錄，執行 `install_docker_tools.sh` 後，部署檔案集中在 `/usr/local/app`：

```text
~/employee-management-system/       # Git Repository（來源）
       │
       └── bash install_docker_tools.sh
                     │
                     ▼
/usr/local/app/                    # Docker Compose 執行目錄
├── Dockerfile
├── docker-compose.yml
├── myWeb.jar
├── manage.sh                     # 來源有此檔時複製
├── README.md                     # 來源有此檔時複製
├── .dockerignore                 # 來源有此檔時複製
├── mysql/
│   ├── conf/
│   ├── init/
│   └── data/
└── nginx/
    ├── conf/nginx.conf
    └── html/
       │
       ▼
docker compose up -d --build
       ├── mysql
       ├── myweb-backend
       └── myweb-frontend
```

**注意：**目前安裝腳本不會自動將 `install_docker_tools.sh`、`connect-podroid.bat`、`connect-podroid.sh` 複製到 `/usr/local/app`。請從 Git Repository 執行安裝腳本；SSH Tunnel 腳本應在要使用瀏覽器的 Windows／macOS／Linux 電腦上執行，而非在 Podroid 內執行。舊部署目錄可能仍殘留以前版本的其他檔案。

Compose 使用固定的 Host Bind Mount：

```text
/usr/local/app/mysql/conf  -> /etc/mysql/conf.d
/usr/local/app/mysql/data  -> /var/lib/mysql
/usr/local/app/mysql/init  -> /docker-entrypoint-initdb.d
/usr/local/app/nginx/conf/nginx.conf -> /etc/nginx/nginx.conf
/usr/local/app/nginx/html  -> /usr/share/nginx/html
```

安裝腳本不會主動清空 MySQL 的 `data`，也不會無條件 `docker compose down`。但同名的設定檔與前端檔案可能在重新部署時被來源覆蓋；更新前仍應備份重要資料。不要只在 `/usr/local/app` 修改設定，因為下次從 Repository 部署可能再次覆蓋。

## 支援條件與已測試環境

執行環境需要 Linux、Bash、Root 權限、可正常運作的 Docker Daemon、Docker Compose V2 與 Buildx。安裝腳本會先檢查工具，缺少時嘗試使用 `apt-get`、`apk`、`dnf` 或 `pacman` 安裝；不保證所有發行版版本、容器或 Android 環境都能自動安裝 Docker Daemon。

| 環境 | 本次驗證 |
| --- | --- |
| WSL Ubuntu 24.04.5 LTS／AMD64 | Temurin Java 17、Spring Boot 啟動及 Compose 三項服務啟動 |
| Podroid Alpine Linux v3.24／ARM64 | JAR 取得、原生 ARM64 後端建置、三項服務啟動及 Podroid 本機 HTTP |
| Windows → Podroid | SSH Tunnel 存取 Nginx 前端；曾完成登入、資料查詢等操作測試 |
| 舊版環境 | 曾使用 UTM／Multipass 測試舊版部署流程，不等於新版完整回歸測試 |

`docker compose ps` 顯示 Running 只是容器狀態，仍應確認前端 HTTP、後端 API、登入和資料庫功能。

## 快速部署

在目標 Linux／Podroid 中：

```bash
git clone https://github.com/NeedMoreCrack/employee-management-system.git
cd employee-management-system
bash -n install_docker_tools.sh
sudo bash install_docker_tools.sh
```

如果已是 Podroid 的 `root` 使用者，最後一行可改為：

```bash
bash install_docker_tools.sh
```

腳本會檢查必要檔案與 Docker 工具、準備 `myWeb.jar`、同步所需檔案到 `/usr/local/app`，再驗證 Compose 並執行 `up -d --build`。不會自動在 Android Wi-Fi 介面設定 HTTP Port Forwarding，也不會在 Windows 上自動建立 SSH Tunnel。

部署後檢查：

```bash
cd /usr/local/app
docker compose ps
curl -I http://127.0.0.1:80/
curl -I http://127.0.0.1:9090/
```

前端正常時通常回傳 HTTP 200；後端根路徑若需授權，回傳 HTTP 401 仍表示 HTTP 服務有回應，但不等於所有 API 均已驗證。

### Dockerfile／Java 17

目前 Dockerfile 採用 `eclipse-temurin:17-jre`，由基底映像提供對應主機架構的 Java 17，不再透過 `ubuntu:latest` 解壓 x86-64 的 `jdk17.tar.gz`。

```dockerfile
FROM eclipse-temurin:17-jre
ENV LANG=C.UTF-8
RUN mkdir -p /app/images
WORKDIR /myWeb
COPY myWeb.jar myWeb.jar
EXPOSE 9090
ENTRYPOINT ["java", "-Dfile.encoding=UTF-8", "-jar", "/myWeb/myWeb.jar"]
```

### `myWeb.jar` 的取得順序

1. Repository 根目錄有非空的 `myWeb.jar` 且不同於部署目錄時，複製到 `/usr/local/app`。
2. 否則如 `/usr/local/app/myWeb.jar` 已存在且非空，就沿用既有版本。
3. 否則 Pull `codeishard/myweb-file:latest`，建立暫存容器並用 `docker cp` 提取 `/files/myWeb.jar`。

檔案載體映像指定 `--platform linux/amd64`，但只使用 `pull/create/cp`，**不會啟動 AMD64 程式**。後端 Runtime 仍由 Temurin 基底映像依裝置 CPU 架構建置。已存在的部署 JAR 不會因遠端 `latest` Tag 更新而自動替換。

## 管理專案：manage.sh

安裝後在目標 Linux 上執行：

```bash
sudo bash /usr/local/app/manage.sh
# 已是 root：bash /usr/local/app/manage.sh
```

管理腳本會操作固定 `/usr/local/app` 的 Compose 專案，選單與目前的 `manage.sh` 一致：

```text
1) 啟動專案
2) 關閉專案
3) 重啟專案
4) 查看 Container 狀態
5) 查看全部 Log
6) 查看 Backend Log
7) 查看 Frontend Log
8) 查看 MySQL Log
9) Rebuild 專案
10) 修復 Frontend（重建容器／重新掛載靜態檔案）
0) 離開
```

第 10 項會單獨執行 `docker compose up -d --force-recreate --no-deps frontend`，檢查 Nginx 容器內是否有 `index.html`，有 `curl` 時再嘗試檢查本機前端 HTTP 200。這個選項不會要求重建 Backend／MySQL。

常用指令（在部署機器）：

```bash
cd /usr/local/app
docker compose ps
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend
docker compose logs --tail=100 mysql
docker compose up -d --build
docker compose down                 # 不加 -v
```

如非 root，請依本機 Docker 權限設定加上 `sudo`。不要隨意刪除 `/usr/local/app/mysql/data`。

## 網路與 Port

| 服務 | Podroid Linux Host Port | Container Port |
| --- | ---: | ---: |
| Nginx 前端（HTTP） | 80 | 80 |
| Spring Boot 後端 | 9090 | 9090 |
| MySQL | 3307 | 3306 |

目前沒有設定 HTTPS 443，前端網址應使用 `http://`。MySQL 不應直接公開在不可信網路。

安裝與管理腳本會嘗試從路由及網路介面取得 **Linux 內部 IP**。例如在一次 Podroid 實測中，Linux `eth0` 是 `10.0.2.15`，Android 手機 Wi-Fi IP 則是 `192.168.0.229`。兩者不同：Docker 顯示 `0.0.0.0:80->80/tcp` 不表示手機 Wi-Fi IP 的 Port 80 一定已對外轉發。以上 IP 僅為測試範例，實際連線要填當前裝置的 IP。

## Podroid SSH Tunnel（Windows／macOS／Linux）

當 Android 已把對外 SSH Port 轉發到 Podroid 的 SSH Server 時，可以在**要開啟前端網頁的電腦**執行 Tunnel 腳本。這兩支腳本就在 Git Repository 根目錄，**不是** `scripts/` 子目錄。

### 使用前準備

1. Podroid 已完成本專案部署，且 `curl -I http://127.0.0.1:80/` 回傳 HTTP 200。
2. Podroid 的 SSH 已啟動；確認 Android 對外 SSH Port。腳本目前預設使用者 `root`、Port `9922`，若與實際設定不同請調整。
3. 在 Android Wi-Fi 設定查詢手機的 IPv4 位址。**輸入手機 Wi-Fi IP，不是 Podroid Linux 內部的 `10.0.2.x`。**
4. 電腦有 OpenSSH Client（`ssh`）。

### Windows

在 Windows 的 Repository 根目錄，雙擊 `connect-podroid.bat`，或透過 CMD／PowerShell 執行：

```powershell
.\connect-podroid.bat
```

腳本會要求輸入 Android Wi-Fi IPv4，然後透過 SSH 建立前後端兩條 Tunnel。此 `.bat` 會呼叫 PowerShell 指令驗證 IPv4，但**不會執行 `.ps1` 腳本**，因此不會遇到 PowerShell `.ps1` 數位簽章執行原則限制。需要變更 SSH 帳號、Port 或本機 Port，可編輯 `.bat` 檔開頭的變數。

### macOS／Linux

在 Repository 根目錄執行：

```bash
bash ./connect-podroid.sh
```

可使用環境變數覆蓋預設值，例如：

```bash
PODROID_USER=root PODROID_SSH_PORT=2222 \
FRONTEND_LOCAL_PORT=18081 BACKEND_LOCAL_PORT=19091 \
bash ./connect-podroid.sh
```

### Tunnel 建立後

輸入 SSH 密碼或使用既有 SSH Key，**保持此連線視窗開啟**。目前兩支 Repository 腳本均使用 `ssh -N`：只建立轉發，**不會進入 Podroid Shell，也不會啟動 Docker 專案**。如果你還要登入 Podroid 進行維護，可以另開普通 SSH 連線；部署完成且服務已運作時，只有 Tunnel 視窗也足夠瀏覽網頁。

| 服務 | 在執行 Tunnel 的電腦瀏覽 |
| --- | --- |
| 前端 | `http://localhost:18080/` |
| 後端 | `http://localhost:19090/` |

```text
電腦 localhost:18080 ── SSH → Android Wi-Fi IP:9922 → Podroid 127.0.0.1:80
電腦 localhost:19090 ── SSH → Android Wi-Fi IP:9922 → Podroid 127.0.0.1:9090
```

`localhost` 指執行腳本的電腦。按 `Ctrl+C` 結束 Tunnel。**不要**用瀏覽器開啟 `http://手機IP:9922/`，因為那是 SSH，不是 HTTP。前端若有寫死其他 API Host／Port，仍需依實際 API 路徑與代理設定進行驗證。

## 問題排查

### Docker 可以啟動，但網頁無法從 Windows 直連

先在 Podroid 內檢查：

```bash
curl -I http://127.0.0.1:80/
curl -I http://127.0.0.1:9090/
ip -4 addr
ss -lnt
```

若 Podroid 本機 HTTP 正常，但 Windows 不能連手機 Wi-Fi IP 的 80／9090，請檢查 Android／Podroid 的 Port Forwarding，或使用上述 SSH Tunnel；**不要僅因無法外連就重建 Docker Image**。

### Nginx 回傳 403／容器內前端目錄是空的

曾遇到 Host 的 `/usr/local/app/nginx/html/index.html` 存在，但 Nginx 容器的 `/usr/share/nginx/html/` 當下顯示空目錄，日誌出現 `directory index ... is forbidden`。可先核對檔案與掛載：

```bash
ls -lah /usr/local/app/nginx/html/
docker exec myweb-frontend ls -lah /usr/share/nginx/html/
docker inspect myweb-frontend --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
docker compose logs --tail=100 frontend
```

本次實測透過以下指令**只重建 Frontend** 後，容器內恢復可見 `index.html`，HTTP 也恢復 200：

```bash
cd /usr/local/app
docker compose up -d --force-recreate --no-deps frontend
curl -I http://127.0.0.1:80/
```

也可在 `manage.sh` 選擇 **10) 修復 Frontend**。這是已驗證的修復方式，但尚不能僅憑此斷定 Podroid 底層掛載異常的根本原因；不需要為這個問題清空 MySQL 或先執行 `chmod 777`。

### SSH Tunnel 無法連上

檢查手機 Wi-Fi IP、Podroid SSH、對外 SSH Port，以及電腦本機 18080／19090 是否已被其他程式使用。Windows 可測試：

```powershell
Test-NetConnection PHONE_IP -Port 9922
Test-NetConnection 127.0.0.1 -Port 18080
curl.exe -I http://127.0.0.1:18080/
```

把 `PHONE_IP` 換成實際手機 IP。SSH Tunnel 視窗關閉後，本機轉發也會結束。

### MySQL 與憑證

Compose 目前將 MySQL Port `3307` 映射到容器 Port `3306`；MySQL 初始化 SQL 只會在資料目錄符合首次初始化條件時執行。資料庫測試密碼目前仍直接出現在 Compose，**公開部署前應改以未追蹤的 `.env`／安全憑證方式管理並輪替密碼**。切勿在 README 中記錄正式密碼。管理腳本不會顯示密碼。

```bash
cd /usr/local/app
docker compose logs --tail=100 mysql
# 如果安裝了 MySQL Client：
mysql -h 127.0.0.1 -P3307 -u root -p
```

## 更新專案

各裝置在自己的 Git Repository 更新後再重新部署：

```bash
cd ~/employee-management-system
git status
git pull --ff-only
bash -n install_docker_tools.sh
sudo bash install_docker_tools.sh
# Podroid 已是 root：bash install_docker_tools.sh
```

若只修改 README，無須為此重新建置 Docker。若需要更新 `/usr/local/app` 內的 README，可自行複製或等下次部署同步。安裝腳本不會主動檢查 Docker Hub 檔案載體是否有新版 JAR。

## 更新紀錄

### 2025-07-08

建立 Docker 安裝及 Compose 部署腳本，整合 Docker、Compose、Buildx、Nginx 與 MySQL。

### 2026-09-24

固定 `/usr/local/app` 為部署目錄，區分 Repository 與 Runtime，並增加持久化資料保留及既有 Ubuntu／Multipass 測試流程；當時大型檔案仍使用 MEGA。

### 2026-09-28

大型檔案來源改為 Docker Hub 檔案載體映像：當時同時包含 JDK 壓縮檔和 `myWeb.jar`。此處為**歷史紀錄**，目前 JDK 壓縮檔方案已停用。

### 2026-10-03

- 後端 Dockerfile 改用跨 AMD64／ARM64 的 `eclipse-temurin:17-jre`。
- 安裝腳本支援多種套件管理器，保留 MySQL 持久化資料，並區分 Linux 內部 IP 與 Android Wi-Fi IP。
- `myWeb.jar` 保留 Docker Hub 檔案載體提取方式。
- `manage.sh` 增加選項 10，供 Nginx 前端容器重建與 HTTP 檢查。
- Repository 根目錄加入 Windows `connect-podroid.bat` 與 macOS／Linux `connect-podroid.sh`，提供互動式 SSH Tunnel。
- README 目錄樹、執行路徑及 SSH／前端 403 問題排查與目前 `main` 分支對齊。
