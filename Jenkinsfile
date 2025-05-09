pipeline {
  agent any

  environment {
    ENV_FILE = "/work/environments/DEV.postman_environment.json"
    COLLECTION_DIR = "/work/collections"
    REPORT_DIR = "/work/reports"
    HTML_REPORT_DIR = "${REPORT_DIR}/html"
    ALLURE_RESULTS_DIR = "allure-results"
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Folders') {
      steps {
        script {
          def timestamp = sh(script: "date +%Y%m%d_%H%M%S", returnStdout: true).trim()
          def backupDir = "/work/report_backup/${timestamp}"

          sh """
            mkdir -p /work/report_backup
            if [ -d "${REPORT_DIR}" ]; then
              mv "${REPORT_DIR}" "${backupDir}"
              chmod -R 755 "${backupDir}"
              echo "📦 備份舊報告到 ${backupDir}"
            fi

            rm -rf "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}"
            mkdir -p "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}"
          """
        }
      }
    }

    stage('Run All Postman Collections') {
      steps {
        script {
          def collections = [
            "01申請廳主買域名",
            "02申請刪除域名",
            "03申請憑證",
            "04申請展延憑證",
            "06申請三級亂數"
          ]

          def successCount = 0

          def totalExecuted = [
            iterations: 0,
            requests: 0,
            testScripts: 0,
            prerequestScripts: 0,
            assertions: 0
          ]
          def totalFailed = [
            iterations: 0,
            requests: 0,
            testScripts: 0,
            prerequestScripts: 0,
            assertions: 0
          ]

          collections.each { col ->
            def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
            def jsonReport = "${REPORT_DIR}/${col}_report.json"
            def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
            def allureReport = "${ALLURE_RESULTS_DIR}/${col}_allure.xml"

            if (fileExists(collectionFile)) {
              echo "🚀 Running collection: ${col}"
              def result = sh (
                script: """
                  newman run "${collectionFile}" \\
                    -e "${ENV_FILE}" \\
                    -r json,cli,html,allure \\
                    --reporter-json-export "${jsonReport}" \\
                    --reporter-html-export "${htmlReport}" \\
                    --reporter-allure-export "${allureReport}"
                """,
                returnStatus: true
              )

              if (result == 0) {
                successCount++
                echo "✅ ${col} executed successfully."
              } else {
                echo "❌ ${col} failed."
              }

              def statsOutput = sh(
                script: """
                  jq -r '.run.stats | to_entries[] | "\\(.key) \\(.value.total) \\(.value.failed)"' ${jsonReport}
                """,
                returnStdout: true
              ).trim()

              statsOutput.eachLine { line ->
                def (key, total, failed) = line.tokenize(' ')
                switch (key) {
                  case 'iterations':
                    totalExecuted.iterations += total.toInteger()
                    totalFailed.iterations += failed.toInteger()
                    break
                  case 'requests':
                    totalExecuted.requests += total.toInteger()
                    totalFailed.requests += failed.toInteger()
                    break
                  case 'testScripts':
                    totalExecuted.testScripts += total.toInteger()
                    totalFailed.testScripts += failed.toInteger()
                    break
                  case 'prerequestScripts':
                    totalExecuted.prerequestScripts += total.toInteger()
                    totalFailed.prerequestScripts += failed.toInteger()
                    break
                  case 'assertions':
                    totalExecuted.assertions += total.toInteger()
                    totalFailed.assertions += failed.toInteger()
                    break
                }
              }
            } else {
              echo "⚠️ 跳過：找不到 collection 檔案：${collectionFile}"
            }
          }

          echo "📊 測試統計結果："
          ['iterations', 'requests', 'testScripts', 'prerequestScripts', 'assertions'].each { key ->
            echo "🔹 ${key.padRight(20)} | executed: ${totalExecuted[key]} | failed: ${totalFailed[key]}"
          }

          currentBuild.result = "SUCCESS"
          currentBuild.description = "✅ 共 ${collections.size()} 組，成功 ${successCount} 組"
          currentBuild.displayName = "#${env.BUILD_NUMBER} - ${successCount}/${collections.size()} 成功"

          // 將統計結果存入 env，供後續 Google Chat 使用
          env.TEST_STATS = ['iterations', 'requests', 'testScripts', 'prerequestScripts', 'assertions'].collect { key ->
            "${key}: executed=${totalExecuted[key]}, failed=${totalFailed[key]}"
          }.join("\\n")
        }
      }
    }

    stage('Merge JSON Results') {
      steps {
        sh '''
          jq -s '.' ${REPORT_DIR}/*_report.json > ${REPORT_DIR}/merged_report.json || true
        '''
      }
    }

    stage('Publish HTML Reports') {
      steps {
        publishHTML(target: [
          reportDir: "${HTML_REPORT_DIR}",
          reportFiles: '*.html',
          reportName: 'Postman HTML Reports'
        ])
      }
    }

    stage('Allure Report') {
      steps {
        allure includeProperties: false,
               jdk: '',
               results: [[path: "${ALLURE_RESULTS_DIR}"]]
      }
    }
  }

  post {
    always {
      echo '🧹 清理臨時文件...'

      script {
        def status = currentBuild.result ?: "UNKNOWN"
        def isSuccess = (status == "SUCCESS")
        def emoji = isSuccess ? "✅" : "❌"
        def imageUrl = isSuccess
          ? "https://i.imgur.com/AD3MbBi.png"
          : "https://i.imgur.com/FYVgU4p.png"

        def cardMessage = [
          cardsV2: [[
            cardId: "jenkins-summary",
            card: [
              header: [
                title: "${emoji} Jenkins 測試結果通知",
                subtitle: "${env.JOB_NAME} #${env.BUILD_NUMBER}",
                imageUrl: imageUrl,
                imageType: "CIRCLE"
              ],
              sections: [[
                widgets: [
                  [decoratedText: [
                    topLabel: "狀態",
                    text: status,
                    startIcon: [iconUrl: imageUrl]
                  ]],
                  [decoratedText: [
                    topLabel: "描述",
                    text: currentBuild.description ?: "無"
                  ]],
                  [decoratedText: [
                    topLabel: "統計資訊",
                    text: env.TEST_STATS.replaceAll("\\\\n", "\n")
                  ]]
                ]
              ]]
            ]
          ]]
        ]

        withCredentials([string(credentialsId: 'GOOGLE_CHAT_WEBHOOK', variable: 'WEBHOOK_URL')]) {
          sh """
            curl -X POST "$WEBHOOK_URL" \\
              -H "Content-Type: application/json" \\
              -d '${groovy.json.JsonOutput.toJson(cardMessage)}' || true
          """
        }
      }
    }
  }
}
