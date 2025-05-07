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
                docker { image 'my-custom-node-image' }  // 使用自定義映像
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
