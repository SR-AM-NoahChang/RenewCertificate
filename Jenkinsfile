pipeline {
  agent any

  environment {
    COLLECTION_DIR = "/work/collections/collections"
    REPORT_DIR = "/work/reports"
    HTML_REPORT_DIR = "/work/reports/html"
    ALLURE_RESULTS_DIR = "ALLURE-RESULTS"
    ENV_FILE = "/work/collections/environments/DEV.postman_environment.json"
    WEBHOOK_URL = credentials('GOOGLE_CHAT_WEBHOOK')
    BASE_URL = "http://maid-cloud.vir999.com"        // ✅ 記得換成實際網址
    YOUR_TOKEN_ENV_VAR = credentials('0f2edbf7-d6f8-4cf7-a248-d38c89cd99fc') // ✅ 使用 Jenkins credential ID
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

    stage('Poll Job Status') {  // ✅ 已清除重複區塊
      steps {
        script {
          def workflowId = sh(script: "jq -r '.item[] | select(.name==\"申請廳主買域名\") | .response[].body' ${REPORT_DIR}/01申請廳主買域名_report.json | jq -r '.workflow_id'", returnStdout: true).trim()

          if (!workflowId || workflowId == "null") {
            error("❌ 無法從報告中取得 workflow_id")
          }

          def expectedJobs = [
            "CheckDomainBlocked",
            "VerifyTLD",
            "UpdateNameServer",
            "UpdateDomainRecord",
            "MergeErrorRecord",
            "RecheckDomainResolution",
            "RemoveTag"
          ]

          def pollMax = 10
          def pollInterval = 60 // 秒
          def success = false

          for (int attempt = 1; attempt <= pollMax; attempt++) {
            echo "⏳ 第 ${attempt} 次輪詢，檢查 Job 狀態..."

            def json = sh(
              script: """curl -s -k -X GET "${BASE_URL}/workflow_api/adm/workflows/${workflowId}/jobs" \\
                -H "Content-Type: application/json" \\
                -H "Authorization: Bearer ${YOUR_TOKEN_ENV_VAR}" """,
              returnStdout: true
            ).trim()

            def jobs = readJSON text: json
            def jobStatuses = jobs.collectEntries { [(it.name): it.status] }
            def failedJobs = jobs.findAll { it.status == "failure" }
            def incompleteJobs = jobs.findAll { it.status != "success" }

            echo "📊 Job 狀態摘要: ${jobStatuses}"

            if (failedJobs) {
              echo "❌ 發現失敗 Job："
              failedJobs.each { echo "🔴 ${it.name} - ${it.status} - ${it.message ?: '無訊息'}" }
              error("❌ Job 中有失敗項目，停止輪詢")
            }

            if (incompleteJobs) {
              echo "⏸️ 尚有 ${incompleteJobs.size()} 個 Job 未完成"
              if (attempt < pollMax) {
                echo "⏲️ 等待 ${pollInterval} 秒後重試..."
                sleep time: pollInterval, unit: 'SECONDS'
              } else {
                error("❌ 已達最大輪詢次數，仍有 Job 未完成")
              }
            } else {
              echo "✅ 所有 Job 已成功完成"
              success = true
              break
            }
          }

          if (!success) {
            error("❌ 輪詢結束但未成功完成")
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
