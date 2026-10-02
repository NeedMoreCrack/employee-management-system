# 使用 Eclipse Temurin JRE 17
# 支援 AMD64 / ARM64，自動選擇對應架構
FROM eclipse-temurin:17-jre

# 設定 Java 環境變數
# JAVA_HOME 與 PATH 已由基礎映像提供

# 統一編碼
ENV LANG=C.UTF-8

# 新增應用資料夾
RUN mkdir -p /app/images

# 設定工作目錄
WORKDIR /myWeb

# 複製應用 JAR 到容器
COPY myWeb.jar myWeb.jar

# 顯示端口
EXPOSE 9090

# 運行 Spring Boot
ENTRYPOINT ["java", "-Dfile.encoding=UTF-8", "-jar", "/myWeb/myWeb.jar"]
