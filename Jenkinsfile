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

// 在 pipeline 外宣告全域變數，避免作用域失效
def results = []

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
        BUILD_TIME = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
    }


    // 在 pipeline 外宣告全域變數，避免作用域失效
def results = []

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
                    mkdir -p "${REPORT_DIR}" "${HTML_REPORT_DIR}" "${ALLURE_RESULTS_DIR}" allure-results
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
                    
                    // 重置 build 說明與結果
                    currentBuild.description = ""
                    currentBuild.result = "SUCCESS"
                    def successCount = 0

                    collections.each { col ->
                        def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
                        def jsonReport = "${REPORT_DIR}/${col}_report.json"
                        def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
                        def allureReport = "${ALLURE_RESULTS_DIR}/${col}_allure.xml"

                        echo "▶️ Running collection: ${col}"
                        def result = sh (
                            script: """
                                newman run "${collectionFile}" \\
                                    -e "${ENV_FILE}" \\
                                    -r cli,json,html,junit,allure \\
                                    --reporter-json-export "${jsonReport}" \\
                                    --reporter-html-export "${htmlReport}" \\
                                    --reporter-allure-export "${allureReport}"
                            """,
                            returnStatus: true
                        )

                        def status = (result == 0) ? "passed" : "failed"
                        if (result == 0) {
                            successCount++
                            echo "✅ ${col} executed successfully."
                        } else {
                            echo "❌ ${col} failed."
                        }
                        // 將每個 collection 結果記錄到全域變數 results
                        results << [collection: col, status: status, details: jsonReport]
                    }

                    env.FAIL_LIST = results.findAll { it.status == "failed" }
                                            .collect { it.collection }
                                            .join(", ")
                    env.SUCCESS_COUNT = results.findAll { it.status == "passed" }.size().toString()
                }
            }
        }

        stage('Merge JSON Results') {
            steps {
                script {
                    // 讀取各 collection 的 JSON 報告，合併成符合 suites 格式的 JSON 結構
                    def suiteResults = results.collect { test ->
                        def jsonContent = readFile(test.details).trim()
                        def jsonData = readJSON text: jsonContent
                        return [collection: test.collection, status: test.status, details: jsonData]
                    }
                    def finalJSON = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(suiteResults))
                    writeFile file: SUITES_JSON, text: finalJSON
                    echo "✅ Allure Report 已整合至 suites.json"
                }
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





