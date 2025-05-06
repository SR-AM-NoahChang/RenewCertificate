pipeline {
    agent any

    environment {
        REPORT_DIR = "reports"
        ENV_FILE = "DEV.postman_environment.json"
    }

    stages {
        stage('Install Dependencies') {
            steps {
                echo "Installing Newman globally..."
                sh 'npm install -g newman'
                sh 'mkdir -p ${REPORT_DIR}'
            }
        }

        stage('Run Postman Collections') {
            steps {
                script {
                    def collections = [
                        "01. 申請廳主買域名 -AutoTest.postman_collection.json",
                        "02. 申請刪除域名-AutoTest.postman_collection.json",
                        "03. 申請憑證-AutoTest.postman_collection.json",
                        "04. 申請展延憑證-AutoTest.postman_collection.json",
                        "06. 申請三級亂數-AutoTest.postman_collection.json"
                    ]

                    def idx = 1
                    for (col in collections) {
                        def reportFile = "${REPORT_DIR}/result${idx}.xml"
                        echo "Running Postman collection: ${col}"
                        sh """
                            newman run "${col}" \
                                -e "${ENV_FILE}" \
                                -r cli,junit \
                                --reporter-junit-export "${reportFile}"
                        """
                        idx++
                    }
                }
            }
        }

        stage('Publish Test Reports') {
            steps {
                echo "Publishing JUnit test reports..."
                junit "${REPORT_DIR}/*.xml"
            }
        }
    }

    post {
        always {
            echo 'Cleaning up temporary files...'
            sh 'ls -lh ${REPORT_DIR} || true'
        }
        failure {
            echo 'Some tests failed. Please check the reports.'
        }
        success {
            echo 'All collections ran successfully!'
        }
    }
}
