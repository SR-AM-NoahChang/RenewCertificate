
// pipeline {
//   agent any

//   environment {
//     ENV_FILE = "/work/environments/DEV.postman_environment.json"
//     COLLECTION_DIR = "/work/collections"
//     REPORT_DIR = "/work/reports"
//     HTML_REPORT_DIR = "${REPORT_DIR}/html"
//     ALLURE_RESULTS_DIR = "${REPORT_DIR}/allure-results"
//     FINAL_ALLURE_DIR = "allure-results"
//     WEBHOOK_URL = "https://chat.googleapis.com/v1/spaces/AAQAGYLH9k0/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=LSRbXq4RX8JcfVt8sXCEMMYNUAcwMcyunOGELvzsBfE"
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
//           rm -rf "${REPORT_DIR}" "${FINAL_ALLURE_DIR}"
//           mkdir -p "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}" "${FINAL_ALLURE_DIR}"
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
//           def failList = []

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

//                 sed -i 's|<testsuite name=.*|<testsuite name="${col}"|' "${junitReport}"
//               """,
//               returnStatus: true
//             )

//             if (result == 0) {
//               successCount++
//               echo "✅ ${col} 執行成功."
//             } else {
//               failList << col
//               echo "❌ ${col} 執行失敗."
//             }
//           }

//           if (successCount == 0) {
//             currentBuild.result = "FAILURE"
//             currentBuild.description = "❌ 所有集合執行失敗"
//           } else {
//             currentBuild.description = "✅ ${successCount} 個集合通過"
//           }

//           // Save failList for webhook usage
//           env.FAIL_LIST = failList.join(", ")
//           env.SUCCESS_COUNT = successCount.toString()
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
//       script {
//         def msg = "❌ Jenkins 測試失敗\n失敗集合：${env.FAIL_LIST ?: '無'}"
//         sh """
//           curl -X POST -H 'Content-Type: application/json' \
//           -d '{ "text": "${msg}" }' "${WEBHOOK_URL}"
//         """
//       }
//     }

//     success {
//       script {
//         def msg = "✅ Jenkins 測試完成，共通過 ${env.SUCCESS_COUNT} 個集合"
//         sh """
//           curl -X POST -H 'Content-Type: application/json' \
//           -d '{ "text": "${msg}" }' "${WEBHOOK_URL}"
//         """
//       }
//     }
//   }
// }



pipeline {
    agent any

    environment {
        ENV_FILE = "/work/environments/DEV.postman_environment.json"
        COLLECTION_DIR = "/work/collections"
        REPORT_DIR = "/work/reports"
        ALLURE_RESULTS_DIR = "${REPORT_DIR}/allure-results"
        WEBHOOK_URL = "https://chat.googleapis.com/v1/spaces/AAQAGYLH9k0/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=HvPXUUnqPlN6c9HhB02kpWleJ86p2lLmDaq32-5t0gQ"
        BUILD_TIME = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
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
                rm -rf "${REPORT_DIR}" "${ALLURE_RESULTS_DIR}"
                mkdir -p "${ALLURE_RESULTS_DIR}"
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

                    def successCount = 0
                    def failList = []

                    collections.each { col ->
                        def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
                        def junitReport = "${ALLURE_RESULTS_DIR}/${col}_junit.xml"

                        echo "Running collection: ${col}"
                        def result = sh (
                            script: """
                            newman run "${collectionFile}" \
                                -e "${ENV_FILE}" \
                                -r junit \
                                --reporter-junit-export "${junitReport}"

                            # 確保 JUnit XML 測試集名稱符合 Allure 的 Suite 規則
                            sed -i 's|<testsuite name=.*|<testsuite name="${col}"|' "${junitReport}"
                            """,
                            returnStatus: true
                        )

                        if (result == 0) {
                            successCount++
                            echo "✅ ${col} 執行成功."
                        } else {
                            failList << col
                            echo "❌ ${col} 執行失敗."
                        }
                    }

                    env.FAIL_LIST = failList.join(", ")
                    env.SUCCESS_COUNT = successCount.toString()
                }
            }
        }

        stage('Prepare Allure Report') {
            steps {
                sh '''
                rm -rf allure-results/*
                mkdir -p allure-results
                cp ${ALLURE_RESULTS_DIR}/*.xml allure-results/
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
            script {
                def msg = "❌ Jenkins 測試失敗\n失敗集合：${env.FAIL_LIST ?: '無'}"
                def payload = """
                {
                  "cards": [
                    {
                      "header": {
                        "title": "❌ 測試失敗通知",
                        "subtitle": "Jenkins Pipeline 執行失敗",
                        "imageUrl": "https://www.jenkins.io/images/logos/jenkins/jenkins.png",
                        "imageStyle": "IMAGE"
                      },
                      "sections": [
                        {
                          "widgets": [
                            {
                              "keyValue": {
                                "topLabel": "執行時間",
                                "content": "${BUILD_TIME}"
                              }
                            },
                            {
                              "keyValue": {
                                "topLabel": "失敗集合",
                                "content": "${env.FAIL_LIST}"
                              }
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
                """
                sh """
                curl -X POST -H 'Content-Type: application/json' \
                -d '${payload}' "${WEBHOOK_URL}"
                """
            }
        }

        success {
            script {
                def msg = "✅ Jenkins 測試完成，共通過 ${env.SUCCESS_COUNT} 個集合"
                def payload = """
                {
                  "cards": [
                    {
                      "header": {
                        "title": "✅ 測試完成通知",
                        "subtitle": "Jenkins Pipeline 執行成功",
                        "imageUrl": "https://www.jenkins.io/images/logos/jenkins/jenkins.png",
                        "imageStyle": "IMAGE"
                      },
                      "sections": [
                        {
                          "widgets": [
                            {
                              "keyValue": {
                                "topLabel": "執行時間",
                                "content": "${BUILD_TIME}"
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
                }
                """
                sh """
                curl -X POST -H 'Content-Type: application/json' \
                -d '${payload}' "${WEBHOOK_URL}"
                """
            }
        }
    }
}

