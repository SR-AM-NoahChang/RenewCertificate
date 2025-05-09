// pipeline {
//   agent any

//   environment {
//     ENV_FILE = "/work/environments/DEV.postman_environment.json"
//     COLLECTION_DIR = "/work/collections"
//     REPORT_DIR = "/work/reports"
//     HTML_REPORT_DIR = "${REPORT_DIR}/html"
//     ALLURE_RESULTS_DIR = "${REPORT_DIR}/allure-results"
//   }

//   stages {
//     stage('Checkout Code') {
//       steps {
//         checkout scm
//       }
//     }

//     stage('Prepare Folders') {
//       steps {
//         script {
//           def timestamp = sh(script: "date +%Y%m%d_%H%M%S", returnStdout: true).trim()
//           def backupDir = "/work/report_backup/${timestamp}"

//           sh """
//             mkdir -p /work/report_backup
//             if [ -d "${REPORT_DIR}" ]; then
//               mv "${REPORT_DIR}" "${backupDir}"
//               echo "📦 備份舊報告到 ${backupDir}"
//             fi

//             rm -rf "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
//             mkdir -p "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
//           """
//         }
//       }
//     }

//     stage('Run All Postman Collections') {
//       steps {
//         script {
//           def collections = [
//             "01申請廳主買域名",
//             "02申請刪除域名",
//             "03申請憑證",
//             "04申請展延憑證",
//             "06申請三級亂數"
//           ]

//           currentBuild.description = ""
//           currentBuild.result = "SUCCESS"
//           def successCount = 0

//           collections.each { col ->
//             def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
//             def jsonReport = "${REPORT_DIR}/${col}_report.json"
//             def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
//             def allureReport = "${ALLURE_RESULTS_DIR}/${col}_allure.xml"

//             echo "Running collection: ${col}"
//             def result = sh (
//               script: """
//                 newman run "${collectionFile}" \\
//                   -e "${ENV_FILE}" \\
//                   -r json,cli,html,allure \\
//                   --reporter-json-export "${jsonReport}" \\
//                   --reporter-html-export "${htmlReport}" \\
//                   --reporter-allure-export "${allureReport}"
//               """,
//               returnStatus: true
//             )

//             if (result == 0) {
//               successCount++
//               echo "✅ ${col} executed successfully."
//             } else {
//               echo "❌ ${col} failed."
//             }
//           }

//           if (successCount == 0) {
//             currentBuild.result = "FAILURE"
//             currentBuild.description = "❌ All collections failed"
//           } else {
//             currentBuild.description = "✅ ${successCount} collections passed"
//           }
//         }
//       }
//     }

//     stage('Merge JSON Results') {
//       steps {
//         sh '''
//           jq -s '.' ${REPORT_DIR}/*_report.json > ${REPORT_DIR}/merged_report.json || true
//         '''
//       }
//     }

//     stage('Publish HTML Reports') {
//       steps {
//         publishHTML(target: [
//           reportDir: "${HTML_REPORT_DIR}",
//           reportFiles: '*.html',
//           reportName: 'Postman HTML Reports'
//         ])
//       }
//     }

//     stage('Prepare Allure Report Folder') {
//       steps {
//         sh '''
//           mkdir -p allure-results
//           cp ${ALLURE_RESULTS_DIR}/*.xml allure-results/ || true
//         '''
//       }
//     }

//     stage('Allure Report') {
//       steps {
//         allure includeProperties: false,
//                jdk: '',
//                results: [[path: 'allure-results']]
//       }
//     }
//   }

//   post {
//     always {
//       echo '🧹 清理臨時文件...'
//     }

//     failure {
//       echo '❌ Build failed: All collections failed to run.'
//     }

//     success {
//       echo '✅ Build succeeded with at least one passing collection.'
//     }
//   }
// }


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

          currentBuild.description = ""
          currentBuild.result = "UNSTABLE"
          def successCount = 0

          collections.each { col ->
            def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
            def jsonReport = "${REPORT_DIR}/${col}_report.json"
            def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
            def allureReport = "${ALLURE_RESULTS_DIR}/${col}_allure.xml"

            if (fileExists(collectionFile)) {
              echo "Running collection: ${col}"
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
            } else {
              echo "⚠️ 跳過：找不到 collection 檔案：${collectionFile}"
            }
          }

          if (successCount == 0) {
            currentBuild.result = "FAILURE"
            currentBuild.description = "❌ 所有 collections 都失敗（但建置仍成功)"
          } else {
            currentBuild.description = "✅ ${successCount} collections 成功執行"
          }
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
        def summary = isSuccess ? "🎉 測試成功！" : "⚠️ 測試失敗"
        def imageUrl = isSuccess
          ? "https://i.imgur.com/AD3MbBi.png"
          : "https://i.imgur.com/FYVgU4p.png"

        def cardMessage = [
          cardsV2: [[
            cardId: "jenkins-summary",
            card: [
              header: [
                title: "${emoji} Jenkins Postman 測試結果",
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
              -d '${groovy.json.JsonOutput.toJson(cardMessage)}'
          """
        }
      }
    }

    failure {
      echo '❌ Build failed: All collections failed to run.'
    }

    success {
      echo '✅ Build succeeded with at least one passing collection.'
    }
  }
}
