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
    stage('Install Dependencies') {
      steps {
        sh '''
          npm install -g newman
          npm install -g allure-commandline
        '''
      }
    }

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
            def anySuccess = false

            collections.each { col ->
                def collectionFile = "${COLLECTION_DIR}/${col}.postman_collection.json"
                def jsonReport = "${REPORT_DIR}/${col}_report.json"
                def htmlReport = "${HTML_REPORT_DIR}/${col}.html"
                def junitReport = "${ALLURE_RESULTS_DIR}/${col}_junit.xml"

                def status = catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE', returnStatus: true) {
                echo "Running collection: ${col}"
                sh """
                    newman run "${collectionFile}" \
                    -e "${ENV_FILE}" \
                    -r json,cli,html,junit \
                    --reporter-json-export "${jsonReport}" \
                    --reporter-html-export "${htmlReport}" \
                    --reporter-junit-export "${junitReport}"
                """
                }
                if (status == 0) {
                anySuccess = true
                }
            }

            if (!anySuccess) {
                echo "❌ All collections failed. Marking build as failed, but continuing for report generation..."
                currentBuild.result = 'FAILURE'
            }
            }
        }
    }


    stage('Merge JSON Results') {
      steps {
        echo 'Merging all JSON results into one file...'
        sh '''
          jq -s '.' ${REPORT_DIR}/*_report.json > ${REPORT_DIR}/merged_report.json
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
      echo 'Cleaning up temp files...'
    }

    success {
      echo '✅ Build succeeded: At least one collection passed.'
    }

    failure {
      echo '❌ Build failed: All collections failed to run.'
    }
  }
}
