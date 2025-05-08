// pipeline {
//   agent any

//   environment {
//     ENV_FILE = "/work/environments/DEV.postman_environment.json"
//     COLLECTION_DIR = "/work/collections"
//     REPORT_DIR = "/work/reports"
//     HTML_REPORT_DIR = "/work/reports/html"
//     ALLURE_RESULTS_DIR = "/work/reports/allure-results"
//   }

//   stages {
//     stage('Checkout Code') {
//       steps {
//         checkout scm
//       }
//     }

//     stage('Prepare Folders') {
//       steps {
//         sh '''
//           mkdir -p "${REPORT_DIR}"
//           mkdir -p "${HTML_REPORT_DIR}"
//           rm -rf "${ALLURE_RESULTS_DIR}" && mkdir -p "${ALLURE_RESULTS_DIR}"
//         '''
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
//             def junitReport = "${ALLURE_RESULTS_DIR}/${col}_junit.xml"

//             echo "Running collection: ${col}"
//             def result = sh (
//               script: """
//                 newman run "${collectionFile}" \
//                   -e "${ENV_FILE}" \
//                   -r cli,json,html,junit \
//                   --reporter-json-export "${jsonReport}" \
//                   --reporter-html-export "${htmlReport}" \
//                   --reporter-junit-export "${junitReport}"

//                 # 強制修改 testsuite 名稱為集合名稱
//                 sed -i 's|<testsuite name=.*|<testsuite name="${col}"|' "${junitReport}"
//               """,
//               returnStatus: true
//             )

//             if (result == 0) {
//               successCount++
//               echo "✅ ${col} 執行成功."
//             } else {
//               echo "❌ ${col} 執行失敗."
//             }
//           }

//           if (successCount == 0) {
//             currentBuild.result = "FAILURE"
//             currentBuild.description = "❌ 所有集合執行失敗"
//           } else {
//             currentBuild.description = "✅ ${successCount} 個集合通過"
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
//           rm -rf allure-results/*
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
//       echo '❌ 構建失敗：所有集合執行失敗。'
//     }

//     success {
//       echo '✅ 構建成功，至少有一個集合通過。'
//     }
//   }
// }


pipeline {
  agent any

  environment {
    COLLECTION_DIR = './collections'
    ENV_FILE = './environments/test.postman_environment.json'
    ALLURE_RESULTS_DIR = 'allure-results'
    ALLURE_REPORT_DIR = 'allure-report'
    WEBHOOK_URL = 'https://chat.googleapis.com/v1/spaces/AAQAGYLH9k0/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=LSRbXq4RX8JcfVt8sXCEMMYNUAcwMcyunOGELvzsBfE'
  }

  stages {
    stage('Prepare') {
      steps {
        script {
          sh "rm -rf ${ALLURE_RESULTS_DIR} ${ALLURE_REPORT_DIR}"
          sh "mkdir -p ${ALLURE_RESULTS_DIR}"

          collections = sh(
            script: "ls ${COLLECTION_DIR} | grep _junit\\.xml | sed 's/_junit\\.xml//'",
            returnStdout: true
          ).trim().split('\n')
        }
      }
    }

    stage('Run Newman Tests') {
      steps {
        script {
          collections.each { col ->
            def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
            def junitReport = "${ALLURE_RESULTS_DIR}/${col}_junit.xml"

            sh """
              newman run "${collectionFile}" \
                -e "${ENV_FILE}" \
                -r junit \
                --reporter-junit-export "${junitReport}"

              # 替換 <testsuite name> 以正確顯示為集合名稱
              sed -i '0,/<testsuite name=/s//<testsuite name="${col}"/' "${junitReport}"
            """
          }
        }
      }
    }

    stage('Generate Allure Report') {
      steps {
        sh "allure generate ${ALLURE_RESULTS_DIR} -o ${ALLURE_REPORT_DIR} --clean"
      }
    }

    stage('Notify via Webhook') {
      steps {
        script {
          def total = sh(script: "grep -c '<testcase' ${ALLURE_RESULTS_DIR}/*.xml || true", returnStdout: true).trim() as Integer
          def failed = sh(script: "grep -c '<failure' ${ALLURE_RESULTS_DIR}/*.xml || true", returnStdout: true).trim() as Integer
          def passed = total - failed
          def passRate = total > 0 ? (passed * 100.0 / total).round(2) : 0
          def reportUrl = "${env.BUILD_URL}allure" // 假設你有安裝 Allure Plugin

          def message = [
            text: "✅ *Postman 測試完成*\n總測試數: *${total}*\n通過: *${passed}*\n失敗: *${failed}*\n成功率: *${passRate}%*\n🔗 [查看報告](${reportUrl})"
          ]

          httpRequest(
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: groovy.json.JsonOutput.toJson(message),
            url: "${WEBHOOK_URL}"
          )
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline 完成"
    }
  }
}
