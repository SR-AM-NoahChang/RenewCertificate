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

        stage('Run All Postman Collections') {
            agent {
                docker {
                    image "${DOCKER_IMAGE}"
                    args "--entrypoint='' -v '$WORKSPACE:/work'"
                }
            }
            steps {
                echo 'Running all Postman collections and aggregating results...'
                sh '''
                set +e
                mkdir -p /work/reports && chmod 777 /work/reports
                echo '{"results":[]}' > /work/reports/final_results.json

                for file in /work/collections/*.postman_collection.json; do
                    echo "▶️ Running collection: $file"

                    newman run "$file" -e /work/environments/DEV.postman_environment.json \
                        -r cli,json \
                        --reporter-json-export "/work/reports/temp_report.json" || true

                    if [ -f /work/reports/temp_report.json ]; then
                        jq --argfile input /work/reports/temp_report.json '.results += $input.results' /work/reports/final_results.json > /work/reports/temp_merged.json
                        mv /work/reports/temp_merged.json /work/reports/final_results.json
                    else
                        echo "❌ temp_report.json not found for $file"
                    fi
                done
                set -e
                '''
            }
        }

        stage('Generate Consolidated HTML Report') {
            agent {
                docker {
                    image "${DOCKER_IMAGE}"
                    args "--entrypoint='' -v '$WORKSPACE:/work'"
                }
            }
            steps {
                echo 'Generating consolidated HTML report using sample collection...'
                sh '''
                newman run /work/collections/01申請廳主買域名.postman_collection.json \
                    -e /work/environments/DEV.postman_environment.json \
                    -r html \
                    --reporter-html-export /work/reports/FinalReport.html || echo "⚠️ HTML report generation failed"
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
            echo '🧹 Cleaning up...'
            sh 'ls -lh reports || true'
        }

        failure {
            echo '❌ Some tests failed. Check the reports.'
            emailext subject: "Postman Tests Failed", 
                     body: "Tests failed. Check the HTML report in Jenkins.", 
                     recipientProviders: [[$class: 'DevelopersRecipientProvider']]
        }
    }
}
