// 

pipeline {
  agent any

  environment {
    COLLECTION_DIR = "/work/collections/collections"
    REPORT_DIR = "/work/reports"
    HTML_REPORT_DIR = "/work/reports/html"
    ALLURE_RESULTS_DIR = "ALLURE-RESULTS"
    ENV_FILE = "/work/collections/environments/DEV.postman_environment.json"
    WEBHOOK_URL = credentials('GOOGLE_CHAT_WEBHOOK')
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Checkout Postman Collections') {
      steps {
        script {
          sh 'rm -rf /work/collections/* || true'
        }
        dir('/work/collections') {
          sh '''
            if [ ! -d .git ]; then
              git clone https://github.com/SR-AM-NoahChang/Maid-postman-auto-tests.git .
            fi
            git fetch origin main
            git reset --hard origin/main
          '''
          sh '''
            echo "✅ 當前 Git commit："
            git rev-parse HEAD
            echo "📝 Commit 訊息："
            git log -1 --oneline
          '''
        }
        sh '''
          echo 🔍 Repo files under /work/collections:
          ls -R /work/collections

          echo 🔍 Checking environment file:
          ls -l /work/collections/environments
        '''
      }
    }

    stage('Prepare Folders') {
      steps {
        script {
          def timestamp = sh(script: "date +%Y%m%d_%H%M%S", returnStdout: true).trim()
          sh """
            mkdir -p /work/report_backup
            if [ -d "${REPORT_DIR}" ]; then
              mv ${REPORT_DIR} /work/report_backup/${timestamp}
              chmod -R 755 /work/report_backup/${timestamp}
              echo 📦 備份舊報告到 /work/report_backup/${timestamp}
            fi
            rm -rf ${REPORT_DIR} ${HTML_REPORT_DIR} allure-results
            mkdir -p ${REPORT_DIR} ${HTML_REPORT_DIR} allure-results
          """
        }
      }
    }

    stage('Run All Postman Collections') {
      steps {
        script {
          if (!fileExists(env.ENV_FILE)) {
            error "❌ 找不到環境檔案：${env.ENV_FILE}"
          }

          def collections = [
            "01申請廳主買域名",
            "02申請刪除域名",
            "03申請憑證",
            "04申請展延憑證",
            "06申請三級亂數"
          ]

          collections.each { name ->
            def path = "${COLLECTION_DIR}/${name}.postman_collection.json"
            if (fileExists(path)) {
              sh """
                echo ▶️ 執行 Postman 測試：${name}
                newman run "${path}" \\
                  --environment "${ENV_FILE}" \\
                  --insecure \\
                  --reporters cli,json,html,junit,allure \\
                  --reporter-json-export "${REPORT_DIR}/${name}_report.json" \\
                  --reporter-html-export "${HTML_REPORT_DIR}/${name}_report.html" \\
                  --reporter-junit-export "${REPORT_DIR}/${name}_report.xml" \\
                  --reporter-allure-export "allure-results" || true
              """
            } else {
              echo "⚠️ 跳過：找不到 collection 檔案：${path}"
            }
          }
        }
      }
    }

stage('Poll Job Status Until Done') {
  steps {
    script {
      def maxAttempts = 30  // 最多輪詢次數
      def interval = 60     // 每次間隔秒數
      def success = false

      for (int i = 1; i <= maxAttempts; i++) {
        echo "🔄 第 ${i} 次檢查 job 狀態..."
        def result = sh(
          script: """
            newman run "${COLLECTION_DIR}/01申請廳主買域名.postman_collection.json" \\
              --folder "Job Status Polling" \\
              --environment "${ENV_FILE}" \\
              --insecure \\
              --reporters cli || true
          """,
          returnStatus: true
        )

        if (result == 0) {
          echo "✅ 所有 job 成功完成，結束輪詢"
          success = true
          break
        } else {
          echo "⌛ 尚未完成，等待 ${interval} 秒..."
          sleep interval
        }
      }

      if (!success) {
        error "❌ 超過 ${maxAttempts} 次輪詢仍未完成或有失敗"
      }
    }
  }
}

    stage('Merge JSON Results') {
      steps {
        sh "jq -s . ${REPORT_DIR}/*_report.json > ${REPORT_DIR}/suites.json || true"
      }
    }

    stage('Publish HTML Reports') {
      steps {
        publishHTML(target: [
          reportDir: "${HTML_REPORT_DIR}",
          reportFiles: 'index.html',
          reportName: 'Postman HTML Reports',
          allowMissing: true,
          alwaysLinkToLastBuild: true,
          keepAll: true
        ])
      }
    }

    stage('Allure Report') {
      steps {
        allure([
          includeProperties: false,
          jdk: '',
          results: [[path: 'allure-results']]
        ])
      }
    }
  }

  post {
    always {
      echo '🧹 清理臨時文件...'
      script {
        def buildResult = currentBuild.currentResult
        def statusEmoji = buildResult == 'SUCCESS' ? '✅' : (buildResult == 'FAILURE' ? '❌' : '⚠️')
        def timestamp = new Date().format("yyyy-MM-dd HH:mm:ss", TimeZone.getTimeZone('Asia/Taipei'))

        def message = """
        {
          "cards": [
            {
              "header": {
                "title": "${statusEmoji} Jenkins Pipeline 執行結果",
                "subtitle": "專案：${env.JOB_NAME} (#${env.BUILD_NUMBER})",
                "imageUrl": "https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/postman-icon.png",
                "imageStyle": "AVATAR"
              },
              "sections": [
                {
                  "widgets": [
                    {
                      "keyValue": {
                        "topLabel": "狀態",
                        "content": "${buildResult}"
                      }
                    },
                    {
                      "keyValue": {
                        "topLabel": "完成時間",
                        "content": "${timestamp}"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        withCredentials([string(credentialsId: 'GOOGLE_CHAT_WEBHOOK', variable: 'WEBHOOK_URL')]) {
          sh """
            curl -k -X POST -H 'Content-Type: application/json' \\
              -d '${message}' \\
              "${WEBHOOK_URL}"
          """
        }
      }
    }
  }
}
