pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'newman-runner'
        WORKSPACE = "/var/jenkins_home/workspace/建站管理_postman"
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
                    echo "Building custom Docker image for Newman..."
                    sh 'docker build --cache-from=$DOCKER_IMAGE -t $DOCKER_IMAGE -f Dockerfile.newman .'
                }
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker {
                    image "${DOCKER_IMAGE}"
                    args "--entrypoint=''" // 不掛載任何本機 volume
                }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                if [ ! -f /work/environments/DEV.postman_environment.json ]; then
                    echo "❌ Environment file not found!"
                    exit 1
                fi

                mkdir -p reports

                newman run /work/collections/01申請廳主買域名.postman_collection.json \
                    -e /work/environments/DEV.postman_environment.json \
                    -r html \
                    --reporter-html-export reports/FinalReport.html || echo "⚠️ HTML report generation failed"
                '''
            }
        }

        stage('Publish Test Reports') {
            steps {
                publishHTML(target: [
                    reportDir: 'reports',
                    reportFiles: 'FinalReport.html',
                    reportName: 'Postman Test Report',
                    keepAll: true
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
