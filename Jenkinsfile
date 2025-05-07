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
                    echo "🔧 Building Docker image for Newman..."
                    sh "docker build -t ${DOCKER_IMAGE} -f Dockerfile.newman ."
                }
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker {
                    image "${DOCKER_IMAGE}"
                    args "-v $WORKSPACE:/work -w /work"
                }
            }
            steps {
                echo '🚀 Running all Postman collections...'
                sh '''
                    mkdir -p reports
                    for file in collections/*.postman_collection.json; do
                        echo "➡️ Running collection: $file"
                        name=$(basename "$file" .postman_collection.json)
                        newman run "$file" -e environments/DEV.postman_environment.json \
                            -r html --reporter-html-export "reports/${name}.html"
                    done
                '''
            }
        }

        stage('Publish Test Reports') {
            steps {
                publishHTML(target: [
                    reportDir: 'reports',
                    reportFiles: '*.html',
                    reportName: '🧪 Postman Test Reports'
                ])
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'ls -lh reports || true'
        }

        failure {
            echo '❌ Some tests failed. Check the reports.'
        }
    }
}
