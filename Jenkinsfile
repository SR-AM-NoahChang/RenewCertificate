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
                    echo "Building custom Docker image for Newman..."
                    sh 'docker build --cache-from=$DOCKER_IMAGE -t $DOCKER_IMAGE -f Dockerfile.newman .'
                }
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { image "${DOCKER_IMAGE}" }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                set +e
                mkdir -p reports
                echo '{"results":[]}' > reports/final_results.json

                for file in collections/*.postman_collection.json; do
                    newman run "$file" -e environments/DEV.postman_environment.json \
                        -r cli,json \
                        --reporter-json-export "reports/temp_report.json"

                    jq '.results += input.results' reports/temp_report.json reports/final_results.json > reports/temp_merged.json
                    mv reports/temp_merged.json reports/final_results.json
                done
                set -e
                '''
            }
        }

        stage('Generate Consolidated HTML Report') {
            steps {
                echo 'Generating single HTML report...'
                sh 'newman-reporter-html reports/final_results.json -o reports/FinalReport.html'
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

        failure {
            echo '❌ Some tests failed. Check the reports.'
            emailext subject: "Postman Tests Failed", 
                    body: "Tests failed, check reports at Jenkins workspace.", 
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
        }
    }
}
