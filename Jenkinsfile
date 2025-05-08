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


import groovy.transform.Field
@Field def results = []

pipeline {
  agent any

  environment {
    ENV_FILE = "/work/environments/DEV.postman_environment.json"
    COLLECTION_DIR = "/work/collections"
    REPORT_DIR = "/work/reports"
    HTML_REPORT_DIR = "${REPORT_DIR}/html"
    ALLURE_RESULTS_DIR = "${REPORT_DIR}/allure-results"
    SUITES_JSON = "${REPORT_DIR}/suites.json"
    WEBHOOK_URL = "https://chat.googleapis.com/v1/spaces/AAQAGYLH9k0/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=HvPXUUnqPlN6c9HhB02kpWleJ86p2lLmDaq32-5t0gQ"
  }

  stages {
    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Set Build Timestamp') {
      steps {
        script {
          env.BUILD_TIME = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
        }
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
              echo "📦 備份舊報告到 ${backupDir}"
            fi

            rm -rf "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
            mkdir -p "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
          """
        }
      }
    }

    stage('Run Postman Collections') {
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

          collections.each { col ->
            def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
            def jsonReport = "${REPORT_DIR}/${col}_report.json"
            def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
            def allureReport = "${ALLURE_RESULTS_DIR}/${col}_allure.xml"

            echo "▶️ Running collection: ${col}"
            def result = sh(
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

            def status = (result == 0) ? "passed" : "failed"
            if (status == "passed") {
              successCount++
              echo "✅ ${col} executed successfully."
            } else {
              echo "❌ ${col} failed."
            }

            results << [collection: col, status: status, jsonPath: jsonReport]
          }

          env.SUCCESS_COUNT = successCount.toString()
          env.FAIL_LIST = results.findAll { it.status == "failed" }
                              .collect { it.collection }
                              .join(", ")
        }
      }
    }

    stage('Generate suites.json') {
      steps {
        script {
          def suiteResults = results.collect { test ->
            def jsonData = readJSON file: test.jsonPath
            def stats = jsonData.run?.stats?.requests ?: [:]
            def timings = jsonData.run?.timings ?: [:]

            return [
              collection: test.collection,
              status: test.status,
              total: stats.total ?: 0,
              failed: stats.failed ?: 0,
              responseTimeAvg: timings.responseAverage ?: 0
            ]
          }

          def output = groovy.json.JsonOutput.prettyPrint(
            groovy.json.JsonOutput.toJson(suiteResults)
          )
          writeFile file: SUITES_JSON, text: output
          echo "✅ 已產生 suites.json"
        }
      }
    }

    stage('Generate Allure Report') {
      steps {
        sh '''
          cp ${ALLURE_RESULTS_DIR}/*.xml allure-results/ || true
          allure generate allure-results -o ${REPORT_DIR}/allure-report || echo "⚠️ 忽略 Allure 錯誤"
        '''
      }
    }

    stage('Publish HTML Report') {
      steps {
        publishHTML(target: [
          reportDir: "${HTML_REPORT_DIR}",
          reportFiles: '*.html',
          reportName: 'Postman HTML Reports'
        ])
      }
    }
  }

  post {
    always {
      echo '🧹 清理臨時文件...'
    }

    failure {
      script {
        def payload = """{
  "cards": [
    {
      "header": {
        "title": "❌ 測試失敗",
        "subtitle": "有 Collection 測試未通過",
        "imageUrl": "https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/postman-icon.png",
        "imageStyle": "IMAGE"
      },
      "sections": [
        {
          "widgets": [
            {
              "keyValue": {
                "topLabel": "產生時間",
                "content": "${env.BUILD_TIME}"
              }
            },
            {
              "keyValue": {
                "topLabel": "失敗集合",
                "content": "${env.FAIL_LIST ?: '全部失敗'}"
              }
            }
          ]
        }
      ]
    }
  ]
}"""
        sh """
          curl -X POST -H 'Content-Type: application/json' \\
               -d '${payload}' \\
               '${env.WEBHOOK_URL}'
        """
      }
    }

    success {
      script {
        def payload = """{
  "cards": [
    {
      "header": {
        "title": "✅ 測試成功",
        "subtitle": "所有報告產生完成",
        "imageUrl": "https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/postman-icon.png",
        "imageStyle": "IMAGE"
      },
      "sections": [
        {
          "widgets": [
            {
              "keyValue": {
                "topLabel": "產生時間",
                "content": "${env.BUILD_TIME}"
              }
            },
            {
              "keyValue": {
                "topLabel": "成功集合數",
                "content": "${env.SUCCESS_COUNT}"
              }
            }
          ]
        }
      ]
    }
  ]
}"""
        sh """
          curl -X POST -H 'Content-Type: application/json' \\
               -d '${payload}' \\
               '${env.WEBHOOK_URL}'
        """
      }
    }
  }
}