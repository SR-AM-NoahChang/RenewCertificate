pipeline {
  agent any

  environment {
    COLLECTION_DIR = "/work/collections/collections"
    REPORT_DIR = "/work/reports"
    HTML_REPORT_DIR = "/work/reports/html"
    ALLURE_RESULTS_DIR = "allure-results"
    ENV_FILE = "/work/collections/environments/DEV.postman_environment.json"
    WEBHOOK_URL = credentials('GOOGLE_CHAT_WEBHOOK')
    BASE_URL = "http://maid-cloud.vir999.com"
    YOUR_TOKEN_ENV_VAR = credentials('0f2edbf7-d6f8-4cf7-a248-d38c89cd99fc')
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
            echo "✅ 當前 Git commit：$(git rev-parse HEAD)"
            echo "📝 Commit 訊息：$(git log -1 --oneline)"
          '''
        }
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
                newman run "${path}" \
                  --environment "${ENV_FILE}" \
                  --insecure \
                  --reporters cli,json,html,junit,allure \
                  --reporter-json-export "${REPORT_DIR}/${name}_report.json" \
                  --reporter-html-export "${HTML_REPORT_DIR}/${name}_report.html" \
                  --reporter-junit-export "${REPORT_DIR}/${name}_report.xml" \
                  --reporter-allure-export "allure-results" || true
              """
            } else {
              echo "⚠️ 跳過：找不到 collection 檔案：${path}"
            }
          }
        }
      }
    }

    stage('Merge JSON Results') {
      steps {
        sh "jq -s . ${REPORT_DIR}/*_report.json > ${REPORT_DIR}/suites.json || true"
      }
    }

    int pollMaxAttempts = 10
    int pollIntervalSeconds = 30

    stage('Poll Workflow Job Status') {
      steps {
        script {
          int attempt = 1
          while (attempt <= pollMaxAttempts) {
            echo "⏳ 第 ${attempt} 次輪詢，時間：${new Date()}"

            // 執行 Postman collection，並將結果存成 JSON
            sh "newman run check-job-status.postman_collection.json --env-var workflowId=${workflowId} --reporters cli,json --reporter-json-export job_status.json"

            // 讀取結果
            def statusJson = readJSON file: 'job_status.json'
            def variables = statusJson.run.executions[-1].result.collectionVariables

            def failedCount = variables.find { it.key == 'poll_failed_job_count' }?.value?.toInteger() ?: 0
            def pendingCount = variables.find { it.key == 'poll_pending_job_count' }?.value?.toInteger() ?: 0

            echo "🔎 第 ${attempt} 次查詢結果：${failedCount} failed, ${pendingCount} pending"

            if (failedCount > 0) {
              error "❌ 輪詢失敗：有 ${failedCount} 個 Job 為 failure"
            }

            if (pendingCount == 0) {
              echo "✅ 所有 job 狀態為 success，輪詢完成"
              break
            }

            echo "🛏️ Sleep 開始時間：${new Date()}"
            sleep pollIntervalSeconds
            echo "😴 Sleep 結束時間：${new Date()}"

            attempt++
          }

          if (attempt > pollMaxAttempts) {
            error "❌ 超過最大輪詢次數 (${pollMaxAttempts})，流程結束"
          }
        }
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
      script {
        def buildResult = currentBuild.currentResult
        def statusEmoji = buildResult == 'SUCCESS' ? '✅' : (buildResult == 'FAILURE' ? '❌' : '⚠️')
        def timestamp = new Date().format("yyyy-MM-dd HH:mm:ss", TimeZone.getTimeZone('Asia/Taipei'))

        def message = """
        {
          \"cards\": [
            {
              \"header\": {
                \"title\": \"${statusEmoji} Jenkins Pipeline 執行結果\",
                \"subtitle\": \"專案：${env.JOB_NAME} (#${env.BUILD_NUMBER})\",
                \"imageUrl\": \"https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/postman-icon.png\",
                \"imageStyle\": \"AVATAR\"
              },
              \"sections\": [
                {
                  \"widgets\": [
                    {
                      \"keyValue\": {
                        \"topLabel\": \"狀態\",
                        \"content\": \"${buildResult}\"
                      }
                    },
                    {
                      \"keyValue\": {
                        \"topLabel\": \"完成時間\",
                        \"content\": \"${timestamp}\"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        writeFile file: 'payload.json', text: message

        withEnv(["WEBHOOK=${WEBHOOK_URL}"]) {
          sh 'curl -k -X POST -H "Content-Type: application/json" -d @payload.json "$WEBHOOK"'
        }
      }
    }
  }
}
