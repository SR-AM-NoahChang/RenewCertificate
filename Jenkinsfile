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

    stage('Run 01申請廳主買域名 並導出環境變數') {
      steps {
        sh '''
          newman run "/work/collections/collections/01申請廳主買域名.postman_collection.json" \
            --environment "${ENV_FILE}" \
            --export-environment "/tmp/exported_env.json" \
            --insecure \
            --reporters cli,json,html,junit,allure \
            --reporter-json-export "${REPORT_DIR}/01_report.json" \
            --reporter-html-export "${HTML_REPORT_DIR}/01_report.html" \
            --reporter-junit-export "${REPORT_DIR}/01_report.xml" \
            --reporter-allure-export "allure-results"
        '''
      }
    }

    stage('Poll Workflow Job Status') {
      steps {
        script {
          def exported = readJSON file: '/tmp/exported_env.json'
          def workflowId = exported.values.find { it.key == 'PD_WORKFLOW_ID' }?.value
          if (!workflowId) {
            error("❌ 無法從 exported_env.json 中取得 PD_WORKFLOW_ID")
          }

          def maxRetries = 10
          def delaySeconds = 300
          def retryCount = 0
          def success = false

          while (retryCount < maxRetries) {
            echo "🔄 第 ${retryCount + 1} 次輪詢 workflow 狀態..."

            def response = sh(
              script: """
                curl -s -X GET "${BASE_URL}/workflow_api/adm/workflows/${workflowId}/jobs" \
                  -H "X-API-Key: ${ADM_KEY}" \
                  -H "Accept: application/json" \
                  -H "Content-Type: application/json"
              """,
              returnStdout: true
            ).trim()

            echo "🔎 取得狀態結果：${response}"

            def json = readJSON text: response

            def failedJobs = json.findAll { it.status == 'failure' }
            def pendingJobs = json.findAll { it.status != 'success' && it.status != 'failure' }

            if (failedJobs.size() > 0) {
              echo "❌ 有 job 失敗，結束輪詢"
              error("❌ Job failure detected: ${failedJobs.collect { it.name }}")
            }

            if (pendingJobs.size() == 0) {
              echo "✅ 所有 job 已完成，提前結束輪詢"
              success = true
              break
            }

            retryCount++
            sleep time: delaySeconds, unit: 'SECONDS'
          }

          if (!success) {
            error("⏰ 超過最大重試次數，workflow 未完成")
          }
        }
      }
    }

    stage('Run 剩餘 Postman Collections') {
      steps {
        script {
          def collections = [
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
