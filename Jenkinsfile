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

          collections.each { col ->
            def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
            def jsonReport = "${REPORT_DIR}/${col}_report.json"
            def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
            def allureOutputDir = "${ALLURE_RESULTS_DIR}/${col}"

            // 容錯但累計成功
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              echo "Running collection: ${col}"
              sh """
                mkdir -p "${allureOutputDir}"
                newman run "${collectionFile}" \
                  -e "${ENV_FILE}" \
                  -r cli,json,html,allure \
                  --reporter-json-export "${jsonReport}" \
                  --reporter-html-export "${htmlReport}" \
                  --reporter-allure-export "${allureOutputDir}"
              """
              successCount++
            }
          }

          // 判斷是否全數失敗
          if (successCount == 0) {
            error("All collections failed. Marking build as failed.")
          } else {
            echo "${successCount} collection(s) ran successfully."
          }
        }
      }
    }

    stage('Merge JSON Results') {
      steps {
        echo 'Merging all JSON results into one file...'
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
        // 請確保 Jenkins 有安裝 Allure plugin 且 CLI 可執行
        allure includeProperties: false,
               jdk: '',
               results: [[path: "${ALLURE_RESULTS_DIR}"]]
      }
    }
  }

  post {
    always {
      echo 'Cleaning up temp files...'
    }

    success {
      echo 'Build succeeded: Some or all collections ran successfully.'
    }

    failure {
      echo 'Build failed: All collections failed to run.'
    }
  }
}
