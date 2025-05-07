pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'newman-runner'
        PATH = "/usr/local/bin:$PATH"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from Git repository...'
                git url: 'https://github.com/SR-AM-NoahChang/Maid-postman-auto-tests.git', branch: 'main'
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

        stage('Debug Newman Execution') {
            steps {
                echo 'Checking Newman installation...'
                sh 'newman -v || echo "⚠️ Newman not found!"'
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { 
                    image "${DOCKER_IMAGE}"
                    args '--entrypoint=""'
                }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                set +e
                mkdir -p /work/reports && chmod 777 /work/reports
                echo '{"results":[]}' > /work/reports/final_results.json

                # Ensure the collections and environment files are in place
                echo "▶️ Running collection: /work/collections/*.postman_collection.json"

                # Run Postman collections using Newman
                for file in /work/collections/*.postman_collection.json; do
                    echo "Running collection: $file"

                    newman run "$file" -e /work/environments/DEV.postman_environment.json \
                        -r cli,json \
                        --reporter-json-export /work/reports/temp_report.json || true

                    if [ -f /work/reports/temp_report.json ]; then
                        # Merge temp_report.json results into final_results.json
                        cat /work/reports/temp_report.json >> /work/reports/final_results.json
                    else
                        echo "❌ Error: temp_report.json not found for collection $file"
                    fi
                done
                set -e
                '''
            }
        }

        stage('Generate Consolidated HTML Report') {
            steps {
                echo 'Generating single HTML report...'
                sh '''
                if ! npm list -g --depth=0 | grep -q newman-reporter-html; then
                    npm install newman-reporter-html --save-dev
                fi

                # Ensure the environment file is available
                if [ ! -f /work/environments/DEV.postman_environment.json ]; then
                    echo "❌ Environment file not found!"
                    exit 1
                fi

                # Run final collection and generate the HTML report
                node_modules/.bin/newman run /work/collections/01申請廳主買域名.postman_collection.json \
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
            echo 'Cleaning up...'
            sh 'ls -lh /work/reports || true'
        }

        failure {
            echo '❌ Some tests failed. Check the reports.'
            emailext subject: "Postman Tests Failed", 
                    body: "Tests failed, check reports at Jenkins workspace.", 
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
        }
    }
}
