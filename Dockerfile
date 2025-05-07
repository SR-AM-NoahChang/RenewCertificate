# 基於 Node 18 官方映像
FROM node:18

# 設置工作目錄
WORKDIR /workspace

# 安裝 newman 和 newman-reporter-html
RUN npm install -g newman newman-reporter-html

# 設置 PATH 環境變數，確保 newman 可用
ENV PATH="/workspace/node_modules/.bin:$PATH"

# 設置容器啟動時的默認命令
CMD ["bash"]
