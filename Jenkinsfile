// pipeline {
//     agent any

//     environment {
//         ENV_FILE = "/work/environments/DEV.postman_environment.json"
//         COLLECTION_DIR = "/work/collections"
//         REPORT_DIR = "/work/reports"
//         ALLURE_RESULTS_DIR = "${REPORT_DIR}/allure-results"
//         ALLURE_REPORT_DIR = "${REPORT_DIR}/allure-report"
//         WEBHOOK_URL = "https://chat.googleapis.com/v1/spaces/..."
//         BUILD_TIME = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
//     }

//     stages {
//         stage('Checkout Code') {
//             steps {
//                 checkout scm
//             }
//         }

//         stage('Prepare Folders') {
//             steps {
//                 sh '''
//                 rm -rf "${REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
//                 mkdir -p "${ALLURE_RESULTS_DIR}" allure-results "${REPORT_DIR}/html"
//                 '''
//             }
//         }

//         stage('Run All Postman Collections') {
//             steps {
//                 script {
//                     def collections = [
//                         "01申請廳主買域名",
//                         "02申請刪除域名",
//                         "03申請憑證",
//                         "04申請展延憑證",
//                         "06申請三級亂數"
//                     ]

//                     def successCount = 0
//                     def failList = []

//                     collections.each { col ->
//                         def sanitizedCol = col.replaceAll(/\s+/, "_")
//                         def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
//                         def junitReport = "${ALLURE_RESULTS_DIR}/${sanitizedCol}_junit.xml"
//                         def htmlReport = "${REPORT_DIR}/html/${sanitizedCol}.html"

//                         echo "Running collection: ${col}"
//                         def result = sh (
//                             script: """
//                             newman run \"${collectionFile}\" \\
//                                 -e \"${ENV_FILE}\" \\
//                                 -r cli,json,html,junit \\
//                                 --reporter-json-export \"${REPORT_DIR}/${sanitizedCol}_report.json\" \\
//                                 --reporter-html-export \"${htmlReport}\" \\
//                                 --reporter-junit-export \"${junitReport}\"

//                             sed -i 's|<testsuite name=\".*\"|<testsuite name=\"${col}\"|' \"${junitReport}\"
//                             sed -i 's|classname=\".*\"|classname=\"${col}\"|' \"${junitReport}\"
//                             """,
//                             returnStatus: true
//                         )

//                         if (result == 0) {
//                             successCount++
//                             echo "✅ ${col} 執行成功."
//                         } else {
//                             failList << col
//                             echo "❌ ${col} 執行失敗."
//                         }
//                     }

//                     env.FAIL_LIST = failList.join(", ")
//                     env.SUCCESS_COUNT = successCount.toString()
//                 }
//             }
//         }

//         stage('Generate Allure Report') {
//             steps {
//                 sh '''
//                 cp ${ALLURE_RESULTS_DIR}/*.xml allure-results/
//                 allure generate --clean allure-results -o ${ALLURE_REPORT_DIR}
//                 '''
//             }
//         }

//         stage('Allure Report') {
//             steps {
//                 allure includeProperties: false,
//                        jdk: '',
//                        results: [[path: 'allure-results']]
//             }
//         }
//     }

//     post {
//         always {
//             echo '🧹 清理臨時文件...'
//         }

//         failure {
//             script {
//                 def payload = """
//                 {
//                   "cards": [
//                     {
//                       "header": {
//                         "title": "❌ 測試失敗通知",
//                         "subtitle": "Jenkins Pipeline 執行失敗",
//                         "imageUrl": "https://www.jenkins.io/images/logos/jenkins/jenkins.png",
//                         "imageStyle": "IMAGE"
//                       },
//                       "sections": [
//                         {
//                           "widgets": [
//                             {
//                               "keyValue": {
//                                 "topLabel": "執行時間",
//                                 "content": "${BUILD_TIME}"
//                               }
//                             },
//                             {
//                               "keyValue": {
//                                 "topLabel": "失敗集合",
//                                 "content": "${env.FAIL_LIST}"
//                               }
//                             }
//                           ]
//                         }
//                       ]
//                     }
//                   ]
//                 }
//                 """
//                 sh """
//                 curl -X POST -H 'Content-Type: application/json' \
//                 -d '${payload}' "${WEBHOOK_URL}"
//                 """
//             }
//         }

//         success {
//             script {
//                 def payload = """
//                 {
//                   "cards": [
//                     {
//                       "header": {
//                         "title": "✅ 測試完成通知",
//                         "subtitle": "Jenkins Pipeline 執行成功",
//                         "imageUrl": "https://www.jenkins.io/images/logos/jenkins/jenkins.png",
//                         "imageStyle": "IMAGE"
//                       },
//                       "sections": [
//                         {
//                           "widgets": [
//                             {
//                               "keyValue": {
//                                 "topLabel": "執行時間",
//                                 "content": "${BUILD_TIME}"
//                               }
//                             },
//                             {
//                               "keyValue": {
//                                 "topLabel": "成功集合數",
//                                 "content": "${env.SUCCESS_COUNT}"
//                               }
//                             }
//                           ]
//                         }
//                       ]
//                     }
//                   ]
//                 }
//                 """
//                 sh """
//                 curl -X POST -H 'Content-Type: application/json' \
//                 -d '${payload}' "${WEBHOOK_URL}"
//                 """
//             }
//         }
//     }
// }

pipeline {
    agent any

    environment {
        ENV_FILE = "/work/environments/DEV.postman_environment.json"
        COLLECTION_DIR = "/work/collections"
        REPORT_DIR = "/work/reports"
        ALLURE_RESULTS_DIR = "${REPORT_DIR}/allure-results"
        WEBHOOK_URL = "https://chat.googleapis.com/v1/spaces/..."
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
                rm -rf "${REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
                mkdir -p "${ALLURE_RESULTS_DIR}" "${REPORT_DIR}/html" allure-results
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
                        def htmlReport = "${REPORT_DIR}/html/${col}.html"
                        def jsonReport = "${REPORT_DIR}/${col}_report.json"

                        echo "▶️ Running collection: ${col}"
                        def result = sh (
                            script: """
                                newman run "${collectionFile}" \\
                                    -e "${ENV_FILE}" \\
                                    -r cli,json,html,junit \\
                                    --reporter-json-export "${jsonReport}" \\
                                    --reporter-html-export "${htmlReport}" \\
                                    --reporter-junit-export "${junitReport}"

                                # Cross-platform sed to fix suite and classname for Allure grouping
                                if [[ "\$(uname)" == "Darwin" ]]; then
                                  sed -i '' 's|<testsuite name=.*|<testsuite name="${col}"|' "${junitReport}"
                                  sed -i '' 's|classname=.*|classname="${col}"|' "${junitReport}"
                                else
                                  sed -i 's|<testsuite name=.*|<testsuite name="${col}"|' "${junitReport}"
                                  sed -i 's|classname=.*|classname="${col}"|' "${junitReport}"
                                fi
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

        stage('Prepare Allure Report Folder') {
            steps {
                sh '''
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

        stage('Generate Static Allure Report') {
            steps {
                sh '''
                    rm -rf ${REPORT_DIR}/allure-report
                    allure generate allure-results -o ${REPORT_DIR}/allure-report || echo "Allure report generation warning ignored"
                '''
            }
        }
    }

    post {
        always {
            echo '🧹 清理臨時文件...'
        }

        failure {
            script {
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
                curl -X POST -H 'Content-Type: application/json' -d '${payload}' "${WEBHOOK_URL}"
                """
            }
        }

        success {
            script {
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
                curl -X POST -H 'Content-Type: application/json' -d '${payload}' "${WEBHOOK_URL}"
                """
            }
        }
    }
}
