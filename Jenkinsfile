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
//           mkdir -p "${ALLURE_RESULTS_DIR}"
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

//           // 讓後面 post 判斷可存取這變數
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
//                 newman run "${collectionFile}" \
//                   -e "${ENV_FILE}" \
//                   -r json,cli,html,allure \
//                   --reporter-json-export "${jsonReport}" \
//                   --reporter-html-export "${htmlReport}" \
//                   --reporter-allure-export "${allureReport}"
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
//           # 清理上次构建的 Allure 结果文件夹
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
//       echo '清理临时文件...'
//     }

//     failure {
//       echo '❌ 構建失敗：所有集合執行失敗。'
//     }

//     success {
//       echo '✅ 構建成功，至少有一个集合通過。'
//     }
//   }
// }

pipeline {
  agent any

  environment {
    ENV_FILE = "/work/environments/DEV.postman_environment.json"
    COLLECTION_DIR = "/work/collections"
    REPORT_DIR = "/work/reports"
    HTML_REPORT_DIR = "/work/reports/html"
    ALLURE_RESULTS_DIR = "/work/reports/allure-results"
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Folders') {
      steps {
        sh '''
          mkdir -p "${REPORT_DIR}"
          mkdir -p "${HTML_REPORT_DIR}"
          rm -rf "${ALLURE_RESULTS_DIR}" && mkdir -p "${ALLURE_RESULTS_DIR}"
        '''
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
          currentBuild.result = "SUCCESS"
          def successCount = 0

          collections.each { col ->
            def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
            def jsonReport = "${REPORT_DIR}/${col}_report.json"
            def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
            def junitReport = "${ALLURE_RESULTS_DIR}/${col}_junit.xml"

            echo "Running collection: ${col}"
            def result = sh (
              script: """
                newman run "${collectionFile}" \
                  -e "${ENV_FILE}" \
                  -r cli,json,html,junit \
                  --reporter-json-export "${jsonReport}" \
                  --reporter-html-export "${htmlReport}" \
                  --reporter-junit-export "${junitReport}"
              """,
              returnStatus: true
            )

            if (result == 0) {
              successCount++
              echo "✅ ${col} 執行成功."
            } else {
              echo "❌ ${col} 執行失敗."
            }
          }

          if (successCount == 0) {
            currentBuild.result = "FAILURE"
            currentBuild.description = "❌ 所有集合執行失敗"
          } else {
            currentBuild.description = "✅ ${successCount} 個集合通過"
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

    stage('Prepare Allure Report Folder') {
      steps {
        sh '''
          rm -rf allure-results/*
          mkdir -p allure-results
          cp ${ALLURE_RESULTS_DIR}/*.xml allure-results/ || true
        '''
      }
    }

    stage('Allure Report') {
      steps {
        allure includeProperties: false,
               jdk: '',
               results: [[path: 'allure-results']]
      }
    }
  }

  post {
    always {
      echo '🧹 清理臨時文件...'
    }

    failure {
      echo '❌ 構建失敗：所有集合執行失敗。'
    }

    success {
      echo '✅ 構建成功，至少有一個集合通過。'
    }
  }
}
