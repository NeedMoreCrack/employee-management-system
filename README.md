

# Employee Management System

使用 Docker Compose 部署 Employee Management System，包含 Spring Boot Backend、Frontend（由 Nginx 提供靜態檔案）、MySQL 與 Nginx。

本專案以 Git Repository 作為原始碼目錄，以 `/usr/local/app` 作為固定部署目錄；可在已具備 Docker 執行條件的 AMD64 / ARM64 Linux 上建置後端映像。**Podroid 的 Linux 內部 IP 不等於 Android 手機的 Wi-Fi IP**；跨裝置存取方式請參考下方網路章節。

## 專案檔案

```text
employee-management-system/
├── Dockerfile
├── docker-compose.yml
├── install_docker_tools.sh   # 環境檢查、檔案準備及部署
├── manage.sh                 # 互動式管理選單
├── README.md
├── mysql/
│   ├── conf/
│   ├── init/
│   └── data/                 # 執行時的持久化資料；請勿提交 Git
└── nginx/
    ├── conf/nginx.conf
    └── html/
```

後端 JAR `myWeb.jar` 不必提交 Git；若本機沒有檔案，部署腳本可從 Docker Hub 的檔案載體映像取得。新版 Dockerfile 使用 `eclipse-temurin:17-jre`，**不再需要 `jdk17.tar.gz` 或 `codeishard/jdk17-file:17`**。

## 部署架構

Repository 可 Clone 至任意位置，例如：

```text
~/employee-management-system      # Git Source
            │
            │ bash install_docker_tools.sh
            ▼
/usr/local/app/                   # 固定 Runtime / Deployment
├── Dockerfile
├── docker-compose.yml
├── myWeb.jar
├── install_docker_tools.sh
├── manage.sh
├── mysql/{conf,init,data}
└── nginx/{conf,html}
            │
            ▼
      docker compose up -d --build
            │
            ├── mysql
            ├── myweb-backend
            └── myweb-frontend
```

`docker-compose.yml` 採用固定 Host Bind Mount：

```yaml
# MySQL
volumes:
  - "/usr/local/app/mysql/conf:/etc/mysql/conf.d"
  - "/usr/local/app/mysql/data:/var/lib/mysql"
  - "/usr/local/app/mysql/init:/docker-entrypoint-initdb.d"

# Nginx（節錄）
volumes:
  - "/usr/local/app/nginx/conf/nginx.conf:/etc/nginx/nginx.conf"
  - "/usr/local/app/nginx/html:/usr/share/nginx/html"
```

安裝腳本會建立部署目錄、複製設定及靜態檔案，**不會主動清空 `mysql/data` 或 `nginx/html`**；對既有 `nginx/html` 中同名檔案仍可能覆蓋。更新前請自行備份重要資料。從 Repository 執行部署時，其 Dockerfile、Compose 及可用設定會同步至 `/usr/local/app`，因此不要只在部署目錄修改設定而不更新來源。

## 已測試環境

| 環境 | 系統與架構 | 驗證內容 |
| --- | --- | --- |
| Windows WSL | Ubuntu 24.04.5 LTS / x86_64（AMD64） | 新版 Dockerfile 建置、Java 17、Spring Boot 啟動、Compose 三服務啟動 |
| Android Podroid | Alpine Linux v3.24 / aarch64（ARM64） | JAR 提取、Temurin ARM64 建置、Compose 三服務啟動；Podroid 內 Nginx HTTP 200、後端根路徑 HTTP 401；Windows SSH Tunnel 可存取前端 |
| 既有歷史測試 | WSL2、macOS UTM Ubuntu VM、Multipass Ubuntu | 舊版部署流程曾測試；不等同已完成此次新版腳本的完整回歸測試 |

Podroid 實測 Docker 29.8.2、Compose v5.1.4、Buildx v0.34.1。WSL 實測 Java 17.0.20.1、Spring Boot 3.3.12。HTTP 401 表示有 HTTP 回應且該請求未獲授權，**不代表登入、資料庫查詢及所有 API 功能均驗證通過**。

## 環境需求與快速部署

- Linux + Bash、Root 權限；Docker Daemon 必須能在該系統正常運作。腳本不能繞過手機或容器環境本身的 Kernel / 虛擬化限制。
- Docker CLI、Docker Compose V2（`docker compose`）及 Buildx；缺少時腳本嘗試使用 `apt-get`、`apk`、`dnf` 或 `pacman` 安裝。各發行版的套件名稱、版本與服務管理方式可能不同，無法保證所有版本皆可自動安裝。
- 網路連線：初次下載 Docker Images 與 JAR 檔案載體時需要。

```bash
git clone https://github.com/NeedMoreCrack/employee-management-system.git
cd employee-management-system
bash -n install_docker_tools.sh
sudo bash install_docker_tools.sh
```

若已經是 Podroid 的 `root` 使用者，可以改用：

```bash
bash install_docker_tools.sh
```

若要測試尚未合併至 `main` 的修改，Clone 時請指定對應分支，例如 `git clone -b feat/multi-arch-docker ...`（以實際推送的分支名稱為準）。

### 部署腳本實際執行內容

1. 檢查 Dockerfile、Nginx Config、Compose 設定與 Root 權限。
2. 讀取 `/etc/os-release` 及 `uname -m`，檢查 Docker CLI／Compose V2／Buildx；缺少時嘗試安裝。
3. 檢查 Docker Daemon，必要時嘗試透過 systemd、OpenRC 或 `service` 啟動。
4. 建立 `/usr/local/app` 及所需資料夾，保留既有持久化資料。
5. 準備 `myWeb.jar`，將 Repository 的 Dockerfile、Compose、管理腳本及存在的設定／靜態檔案複製至部署目錄。
6. 執行 `docker compose config -q` 驗證組態，再執行 `docker compose up -d --build`；Compose 負責拉取缺少的服務映像。
7. 顯示容器狀態、Linux 內部 IP、本機 HTTP 存取方式及可能需要的網路轉發提示。

**新版不會在每次部署前無條件執行 `docker compose down`，也不會自動強制刪除舊 Container、Network 或 Volume。** 服務若有設定變化，Compose 會依需要建立或重建容器。`up -d` 回傳成功也不代表所有業務功能已就緒。

## Backend JAR 與跨架構 Dockerfile

原本 `ubuntu:latest` 加上手動 `COPY jdk17.tar.gz`／解壓 JDK 17.0.12 的方式已移除。現在改用支援 AMD64、ARM64 的 Temurin JRE 17 基底映像；實際版本依建置時取得的 Tag 對應內容而定。

目前 Dockerfile：

```dockerfile
FROM eclipse-temurin:17-jre
ENV LANG=C.UTF-8
RUN mkdir -p /app/images
WORKDIR /myWeb
COPY myWeb.jar myWeb.jar
EXPOSE 9090
ENTRYPOINT ["java", "-Dfile.encoding=UTF-8", "-jar", "/myWeb/myWeb.jar"]
```

`C.UTF-8` 與原先的 `en_US.UTF-8` 並非完全相同的地區設定；若應用程式依賴語系排序或日期／數字格式，請另外測試。

### `myWeb.jar` 取得順序

1. 若 Repository 根目錄存在非空的 `myWeb.jar` 且來源與部署路徑不同，複製至 `/usr/local/app/myWeb.jar`。
2. 否則若部署目錄已存在非空 JAR，沿用既有版本。
3. 否則從 `codeishard/myweb-file:latest` Pull 檔案載體、使用暫時 Container 與 `docker cp` 取出 `/files/myWeb.jar`；完成後移除暫時 Container。

此檔案載體目前指定 `--platform linux/amd64`：在 ARM64 裝置上只執行 `docker pull`、`docker create`、`docker cp`，**不啟動或執行 AMD64 容器程式**。真正的後端 Runtime 仍依部署機器架構由 `eclipse-temurin:17-jre` 建置。

手動取出 JAR 的範例（確定目標位置可覆寫後再執行）：

```bash
sudo docker pull --platform linux/amd64 codeishard/myweb-file:latest
sudo docker create --platform linux/amd64 --name temp-myweb-file \
  codeishard/myweb-file:latest /bin/true
sudo docker cp temp-myweb-file:/files/myWeb.jar /usr/local/app/myWeb.jar
sudo docker rm temp-myweb-file
```

> `latest` 是可變 Tag。既有 `/usr/local/app/myWeb.jar` 不會因再次執行安裝腳本而自動更新；若要替換版本，請明確更新 Repository 中的 JAR 或備份後替換部署目錄檔案。不要再依賴舊的 JDK 壓縮檔 Image。

## 使用 manage.sh 管理專案

部署成功後可以直接從任意工作目錄執行：

```bash
sudo bash /usr/local/app/manage.sh
# Podroid root：bash /usr/local/app/manage.sh
```

管理腳本會明確使用 `/usr/local/app` 的 Compose 設定，不會因為 Shell 當前目錄不同而切換到另一個 Compose Project。

```text
1) 啟動專案                docker compose up -d
2) 關閉專案                docker compose down（不使用 -v）
3) 重啟專案                docker compose up -d --force-recreate
4) 查看 Container 狀態
5) 查看全部 Log
6) 查看 Backend Log
7) 查看 Frontend Log
8) 查看 MySQL Log
9) Rebuild 專案            docker compose up -d --build
0) 離開
```

查看即時 Log 時，按 `Ctrl+C` 停止追蹤。管理畫面不再直接列印 MySQL 密碼；請從自己的本機 Compose／`.env` 設定確認憑證，不要把正式密碼提交至公開 Repository。

### 不使用選單的常用指令

```bash
cd /usr/local/app
sudo docker compose ps
sudo docker compose up -d
sudo docker compose up -d --build
sudo docker compose logs -f
sudo docker compose logs --tail=100 backend
sudo docker compose logs --tail=100 frontend
sudo docker compose logs --tail=100 mysql
sudo docker compose down
```

Podroid 若已是 Root，不需要加 `sudo`。`docker compose down` 不等於刪除 Bind Mount 中的 `/usr/local/app/mysql/data`；但它會停止／移除此專案容器與 Compose Network，請留意停機影響。**勿隨意使用 `down -v` 或刪除 MySQL 資料夾。**

## 網路、Linux IP 與 Podroid 特別說明

### 服務埠

| 服務 | Linux Host Port | Container Port | 說明 |
| --- | ---: | ---: | --- |
| Nginx 前端 | 80 | 80 | 使用 `http://`，目前未配置 HTTPS 443 |
| Spring Boot 後端 | 9090 | 9090 | 根路徑可能回傳 HTTP 401 |
| MySQL | 3307 | 3306 | 請避免對不可信網路公開資料庫 |

目前兩支新版腳本會優先以 `ip -4 route get 1.1.1.1` 的 `src` 取得 Linux IP，再依序嘗試 `hostname -I` 和 `ip -4 -o addr`，避免單獨依賴 Alpine BusyBox 不一定支援的 `hostname -I`。取得的是 **Linux 環境內部位址**，不保證其他裝置可直接連上。

```bash
ip -4 addr
ip -4 route get 1.1.1.1
ss -lnt
```

### Podroid 的 NAT / 虛擬網路

此次實測：

```text
Android Wi-Fi IP：192.168.0.229       # 實測範例，請依當前網路替換
Android SSH Port：9922
Podroid Linux eth0：10.0.2.15/24
Podroid SSH：內部 Port 22
Podroid Docker：0.0.0.0:80、0.0.0.0:9090、0.0.0.0:3307
```

**Docker 顯示 `0.0.0.0:80->80/tcp` 僅表示 Port 已發佈到 Podroid Linux 的網路環境，不代表 Android Wi-Fi IP 會自動對外開放 Port 80。** 此次 Windows 可 SSH 到 `192.168.0.229:9922`，但無法直接連線該 IP 的 Port 80；在 Podroid Linux 內使用 `127.0.0.1:80` 回傳 HTTP 200、`127.0.0.1:9090` 回傳 HTTP 401。

如需直接從區網存取，必須確認 Android／Podroid 是否支援另行設定 TCP Port Forwarding；本專案安裝腳本不會自動修改 Android 端的轉發設定，也不會猜測手機 Wi-Fi IP。

### Windows → Podroid：已驗證可用的 SSH Tunnel

在 Windows PowerShell 開啟一個終端機：

```powershell
ssh -N -p 9922 `
  -L 18080:127.0.0.1:80 `
  -L 19090:127.0.0.1:9090 `
  root@192.168.0.229
```

保持 SSH 視窗開啟，接著在**Windows 本機**使用：

| 項目 | Windows 瀏覽器／請求網址 |
| --- | --- |
| 前端 | `http://localhost:18080/` |
| 後端 | `http://localhost:19090/` |

手機 IP 和 SSH Port 請依實際環境替換。上述轉發的 `localhost` 指 Windows 自己，不是手機；瀏覽器不要用 `http://192.168.0.229:9922/`，因為 9922 是 SSH，並非 HTTP。前端若有寫死 API Host／Port，還需要另外檢查前端的 API 設定。

也可寫入 Windows 的 `$HOME\.ssh\config`：

```sshconfig
Host podroid
    HostName 192.168.0.229
    User root
    Port 9922
    LocalForward 18080 127.0.0.1:80
    LocalForward 19090 127.0.0.1:9090
    ExitOnForwardFailure yes
```

之後使用 `ssh -N podroid`。建議以 SSH Key 認證並避免將 Root 密碼登入暴露於不可信網路。

## MySQL 連線與資料安全

目前 Compose 對外映射 Linux Port `3307` → MySQL Container `3306`，預設資料庫名稱為 `restful`。實際使用者／密碼以本機配置為準，README 不公開列出密碼。

Podroid Linux 內若有安裝 MySQL Client，可嘗試：

```bash
mysql -h 127.0.0.1 -P3307 -u root -p
```

或先檢查：

```bash
cd /usr/local/app
docker compose logs --tail=100 mysql
```

MySQL 首次初始化時，`mysql/init` 內的 SQL 只會在資料目錄符合初始化條件時執行；重複部署不會自動重新初始化既有資料庫。建議將密碼移到未納入 Git 的 `.env`／安全憑證設定，並對現有測試用密碼做必要輪替。

## 問題排查

**安裝腳本要求 Root：**

```bash
sudo bash install_docker_tools.sh
# Podroid 已是 root 時：bash install_docker_tools.sh
```

**Docker Socket 權限或 Daemon 問題：**

```bash
sudo docker info
sudo docker ps
# Ubuntu/systemd 環境可依實際情況：sudo systemctl start docker
# Alpine/OpenRC 可依實際情況：rc-service docker start
```

不要假設 Podroid 一定提供 systemd。

**檢查部署檔案：**

```bash
ls -lah /usr/local/app
ls -lh /usr/local/app/myWeb.jar
ls -l /usr/local/app/nginx/conf/nginx.conf
```

新版不再要求 `/usr/local/app/jdk17.tar.gz`；舊資料夾若殘留此檔，不代表新版部署仍會使用它。請先確定新版正常後再自行清理。

**檢查 Compose 與啟動日誌：**

```bash
cd /usr/local/app
sudo docker compose config -q
sudo docker compose ps
sudo docker compose logs --tail=100 backend
sudo docker compose logs --tail=100 frontend
sudo docker compose logs --tail=100 mysql
```

**檢查 HTTP：**

```bash
curl -v --max-time 5 http://127.0.0.1:80/
curl -v --max-time 5 http://127.0.0.1:9090/
```

若 Podroid Linux 本機可存取、Windows 直連 Android IP 不可存取，先檢查 Android／Podroid Port Forwarding，或使用上面的 SSH Tunnel，**不要只因外部連不上就重建 Docker Image**。

**Container 名稱衝突：**先用 `docker ps -a` 查明容器所屬專案；新版腳本不再直接強制刪除同名舊容器，請自行確認後處理，避免誤刪其他專案。

## 更新專案

在各自裝置的 Git Repository 中更新，然後重新部署：

```bash
cd ~/employee-management-system
git pull --ff-only
bash -n install_docker_tools.sh
sudo bash install_docker_tools.sh
# Podroid root：bash install_docker_tools.sh
```

如果正在測試尚未合併的分支，請先確認 `git branch --show-current` 與 `git status`，再決定要 Pull 哪個分支。部署腳本優先沿用既有的部署 JAR（除非 Repository 提供新的非空 JAR），不會自動檢查遠端 JAR 是否更新。

## 更新紀錄

### 2025-07-08

建立 Docker 安裝與 Compose 部署腳本，整合 Docker、Compose、Buildx、Nginx 與 MySQL。

### 2026-09-24

固定 `/usr/local/app` 為部署目錄，區分 Git Repository 與 Runtime，新增檔案同步、既有 MySQL 資料保留及 Multipass 初始化測試；當時大型檔案仍使用 MEGA 下載。

### 2026-09-28

大型檔案來源由 MEGA 改為 Docker Hub 的檔案載體映像：`codeishard/jdk17-file:17` 和 `codeishard/myweb-file:latest`。這是**歷史版本紀錄**；目前 JDK 壓縮檔方案已停用。

### 2026-10-03

- Dockerfile 改用跨 AMD64／ARM64 的 `eclipse-temurin:17-jre`，移除 `jdk17.tar.gz` 依賴。
- 安裝腳本支援多套件管理器；先檢查 Docker／Compose／Buildx，再準備 JAR 與部署檔案，不再預設 `compose down` 並強制清理既有資源。
- `myWeb.jar` 繼續使用 Docker Hub 檔案載體；提取時明確指定 `linux/amd64`，不執行載體容器。
- `install_docker_tools.sh`、`manage.sh` 改善 Linux IP 偵測，區分 Podroid 內部 IP 與 Android Wi-Fi IP；管理選單不再列印 MySQL 密碼。
- WSL Ubuntu AMD64 與 Podroid Alpine ARM64 均完成建置及三服務啟動測試；Podroid 的本機 HTTP 及 Windows SSH Tunnel 實測成功。

## Podroid SSH Tunnel（Windows / macOS / Linux）

Podroid Linux 可能使用獨立的虛擬網路。即使 Docker Compose 顯示 `0.0.0.0:80->80/tcp`，Android 手機的 Wi-Fi IP 也不一定能直接連入前端。若手機已將 SSH 對外轉發，可使用本專案的 SSH Tunnel 腳本，從**執行腳本的電腦**存取 Podroid 內的 Nginx 與 Spring Boot，不必額外開放 Android 的 80／9090 Port。

### 使用前準備

1. 先在 Podroid 完成專案部署，並確認 Linux 內執行 `curl -I http://127.0.0.1:80/` 有 HTTP 回應；後端可用 `curl -I http://127.0.0.1:9090/` 檢查（根路徑回傳 `401` 可能是正常的驗證結果）。
2. 啟用 Podroid SSH，確認 Android 對外 SSH Port 可連線。以下腳本預設 SSH 帳號 `root`、Port `9922`；新環境若不同，請依實際設定調整。
3. 在 Android 的 Wi-Fi 設定查看**手機 Wi-Fi IPv4**（例如 `192.168.0.229`）。不要輸入 Podroid 虛擬網卡的 `10.0.2.15`。使用端需要有 OpenSSH Client（`ssh`）。

### 腳本與執行方式

建議把兩支檔案放在 Repository 的 `scripts/` 目錄：

```text
scripts/
├── connect-podroid.bat    # Windows（可雙擊）
└── connect-podroid.sh     # macOS / Linux
```

| 平台 | 執行方式 |
| --- | --- |
| Windows | 雙擊 `connect-podroid.bat`，或在 CMD／PowerShell 執行 ` .\scripts\connect-podroid.bat` |
| macOS | `bash ./scripts/connect-podroid.sh` |
| Linux | `bash ./scripts/connect-podroid.sh` |

> 上述指令假設目前位置是 Repository 根目錄；若檔案放在其他位置，請調整路徑。Windows 的 `.bat` 版本不必執行 `.ps1` 檔，因此不受 PowerShell 腳本數位簽章執行原則限制；它會使用 PowerShell 命令來驗證輸入的 IPv4。

執行後依提示輸入 Android 手機的 Wi-Fi IP，接著依 SSH 提示輸入密碼或使用既有 SSH Key。**SSH Tunnel 視窗要保持開啟**；SSH 的 `-N` 模式只負責轉發，不會進入遠端互動 Shell。

### 連線後的網址

| 服務 | 在執行 Tunnel 的電腦上開啟 |
| --- | --- |
| Frontend（Podroid Port 80） | `http://localhost:18080/` |
| Backend（Podroid Port 9090） | `http://localhost:19090/` |

轉發路徑如下：

```text
本機 localhost:18080 -> SSH（Android Wi-Fi IP:9922）-> Podroid 127.0.0.1:80
本機 localhost:19090 -> SSH（Android Wi-Fi IP:9922）-> Podroid 127.0.0.1:9090
```

兩支腳本預設只監聽執行端的本機 Loopback，不會因此將網頁開放給整個區網。按 `Ctrl+C` 中止連線。請使用 `http://`，不要將 SSH Port `9922` 當成網頁 Port，也不要假設已配置 HTTPS。

### 自訂設定與排查

- **Windows `.bat`**：可直接編輯檔案開頭的 `SSH_USER`、`SSH_PORT`、`FRONTEND_LOCAL_PORT`、`BACKEND_LOCAL_PORT`，預設依序為 `root`、`9922`、`18080`、`19090`。
- **macOS／Linux `.sh`**：可使用環境變數覆蓋預設值，例如：

  ```bash
  PODROID_USER=root PODROID_SSH_PORT=2222 FRONTEND_LOCAL_PORT=18081 BACKEND_LOCAL_PORT=19091 bash ./scripts/connect-podroid.sh
  ```

- 如果提示本機 18080／19090 已被占用，請先關閉舊 Tunnel 或修改本機 Port。
- 如果 SSH 無法連線，先確認手機 Wi-Fi IP、Podroid SSH 是否啟動，以及 Android 對外 SSH Port 是否正確。
- 如果前端畫面能開啟，但登入／資料查詢失敗，請確認前端 API Base URL 是否仍指向其他 IP／Port；必要時檢查 API URL 與 CORS。**前端 HTTP 200 不代表全部 API 已通過測試。**

這兩支腳本只建立 SSH 轉發，**不負責啟動 Podroid、SSH Server 或 Docker Compose**。
