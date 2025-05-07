pipeline {
    agent none
    stages {
        stage('Checkout Code') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            agent {
                docker { image 'node:18' }
            }
            steps {
                echo 'Installing Newman globally...'
                sh 'npm install -g newman newman-reporter-html'
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { image 'node:18' }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                mkdir -p reports
                for file in *.postman_collection.json; do
                    newman run "$file" -e DEV.postman_environment.json \
                      -r cli,html \
                      --reporter-html-export "reports/${file%.json}.html"
                done
                '''
            }
        }

        stage('Publish Test Reports') {
            agent none
            steps {
                publishHTML(target: [
                    reportDir: 'reports',
                    reportFiles: '*.html',
                    reportName: 'Postman Test Report'
                ])
            }
        }
    }

    post {
        always {
            echo 'Cleaning up temporary files...'
            sh 'ls -lh reports || true'
        }

        failure {
            echo 'Some tests failed. Please check the reports.'
        }
    }
}
