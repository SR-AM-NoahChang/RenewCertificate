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
    ADM_KEY = credentials('ADM_KEY')
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

    stage('Export Environment with workflowId') {
      steps {
        sh """
          newman run "${COLLECTION_DIR}/01申請廳主買域名.postman_collection.json" \\
            --environment "${ENV_FILE}" \\
            --insecure \\
            --export-environment "/tmp/exported_env.json" \\
            --reporters cli,json \\
            --reporter-json-export "${REPORT_DIR}/01申請廳主買域名_report.json"
        """
      }
    }

    stage('Load workflowId') {
      steps {
        script {
          def exportedEnv = readJSON file: "/tmp/exported_env.json"
          def pwfId = exportedEnv.values.find { it.key == 'PD_WORKFLOW_ID' }?.value

          if (!pwfId) {
            error "❌ 無法從 exported_env.json 找到 PD_WORKFLOW_ID"
          }

          env.PD_WORKFLOW_ID = pwfId
          echo "🆔 擷取到 PD_WORKFLOW_ID: ${env.PD_WORKFLOW_ID}"
        }
      }
    }

    stage('Poll Workflow Job Status') {
      steps {
        script {
          def maxRetries = 10
          def delaySeconds = 300
          def retryCount = 0
          def success = false

          while (retryCount < maxRetries) {
            echo "🔄 第 ${retryCount + 1} 次輪詢 workflow 狀態 (ID=${env.PD_WORKFLOW_ID})..."

            def response = sh(
              script: """
                curl -s -X GET "${BASE_URL}/workflow_api/adm/workflows/${env.PD_WORKFLOW_ID}/jobs" \\
                  -H "Accept: application/json" \\
                  -H "Content-Type: application/json" \\
                  -H "X-API-Key: ${ADM_KEY}"
              """,
              returnStdout: true
            ).trim()

            echo "🔎 回傳：${response}"

            def jobs
            try {
              def json = readJSON text: response
              jobs = json // 如果回傳本身就是 array
              if (!(jobs instanceof List)) {
                error "❌ 回傳格式錯誤，預期為 job 陣列"
              }
            } catch (err) {
              error "❌ 解析 JSON 回傳失敗：${err.message}"
            }

            def failedJobs = jobs.findAll { it.status == 'failure' }
            def pendingJobs = jobs.findAll { it.status != 'success' && it.status != 'failure' }

            if (failedJobs.size() > 0) {
              echo "❌ 發現失敗的 Job："
              failedJobs.each { job -> echo "🔴 ${job.name} -> ${job.status}" }
              error "輪詢失敗：存在 failure 狀態的 job"
            }

            if (pendingJobs.size() > 0) {
              echo "⏳ 尚有未完成 Job："
              pendingJobs.each { job -> echo "🟡 ${job.name} -> ${job.status}" }
            } else {
              echo "✅ 所有 job 成功完成！"
              success = true
              break
            }

            retryCount++
            sleep time: delaySeconds, unit: 'SECONDS'
          }

          if (!success) {
            error "⏰ 達到最大輪詢次數仍未完成"
          }
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
            // "01申請廳主買域名", // 已提前執行過，避免重複
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
