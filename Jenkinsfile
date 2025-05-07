pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'newman-runner'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Newman Docker Image') {
            steps {
                script {
                    echo "Building Docker image for Newman..."
                    sh 'docker build -t $DOCKER_IMAGE -f Dockerfile.newman .'
                }
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { image "${DOCKER_IMAGE}" }
            }
            steps {
                echo 'Running all Postman collections...'
                sh '''
                    set -x  # Enable command tracing for better debugging
                    mkdir -p reports
                    for file in $(find collections -name "*.json"); do
                        echo "➡️ Running collection: $file"
                        name=$(basename "$file" .json)
                        echo "Full path for collection: $file"
                        newman run "$file" -e environments/DEV.postman_environment.json -r html --reporter-html-export "reports/${name}.html" || {
                            echo "❌ Newman failed for $file"
                            exit 1
                        }
                    done
                '''
            }
        }

        stage('Publish Test Reports') {
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

        failure {
            echo '❌ Some tests failed. Check the reports.'
        }
    }
}
