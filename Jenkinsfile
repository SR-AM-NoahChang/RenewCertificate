pipeline {
    agent none

    stages {
        stage('Checkout Code') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { image 'newman-runner' }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                mkdir -p reports
                for file in collections/*.postman_collection.json; do
                    newman run "$file" -e environments/DEV.postman_environment.json \
                      -r cli,html \
                      --reporter-html-export "reports/$(basename "${file%.json}.html")"
                done
                '''
            }
        }

        stage('Publish Test Reports') {
            agent any
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
            echo 'Cleaning up...'
            sh 'ls -lh reports || true'
        }
    }
}
