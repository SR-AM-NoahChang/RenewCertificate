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

        stage('Verify Environment Files') {
            steps {
                echo 'Checking Postman environment files...'
                sh '''
                mkdir -p $WORKSPACE/environments
                ls -lh $WORKSPACE/environments
                '''
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { 
                    image "${DOCKER_IMAGE}"
                    args "--entrypoint='' -v '$WORKSPACE/environments:/work/environments'"
                }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                if [ ! -f /work/environments/DEV.postman_environment.json ]; then
                    echo "❌ Environment file not found!"
                    exit 1
                fi

                /usr/bin/newman run collections/01申請廳主買域名.postman_collection.json \
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
