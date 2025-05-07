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
                    args "--entrypoint='' -v '$WORKSPACE:/work'"
                }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                mkdir -p /work/reports

                newman run /work/collections/01申請廳主買域名.postman_collection.json \
                    -e /work/environments/DEV.postman_environment.json \
                    -r html,junitfull \
                    --reporter-html-export /work/reports/FinalReport.html \
                    --reporter-junitfull-export /work/reports/result.xml || echo "⚠️ Report generation failed"
                '''
            }
        }

        stage('Publish Test Reports') {
            steps {
                // Publish Newman HTML Report
                publishHTML(target: [
                    reportDir: 'reports',
                    reportFiles: 'FinalReport.html',
                    reportName: 'Postman Test Report',
                    keepAll: true
                ])

                // Publish JUnit XML Report
                junit allowEmptyResults: true, testResults: 'reports/result.xml'
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
