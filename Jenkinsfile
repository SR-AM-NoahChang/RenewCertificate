pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'newman-runner'
        WORKSPACE = "${env.WORKSPACE}"
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

        stage('Debug Newman Execution') {
            steps {
                echo 'Checking Newman installation...'
                sh '/usr/bin/newman -v || echo "⚠️ Newman not found!"'
            }
        }

        stage('Verify Environment Files') {
            steps {
                echo 'Checking Postman environment files...'
                sh 'ls -lh $WORKSPACE/environments || echo "⚠️ Environment files missing!"'
            }
        }

        stage('Run Postman Collections') {
            agent {
                docker { 
                    image "${DOCKER_IMAGE}"
                    args "--entrypoint='' -v $WORKSPACE/environments:/work/environments"
                }
            }
            steps {
                echo 'Running Postman collections...'
                sh '''
                set +e
                mkdir -p reports && chmod 777 reports
                echo '{"results":[]}' > reports/final_results.json

                if [ ! -f /work/environments/DEV.postman_environment.json ]; then
                    echo "❌ Environment file not found!"
                    exit 1
                fi

                for file in collections/*.postman_collection.json; do
                    echo "Running collection: $file"

                    /usr/bin/newman run "$file" -e /work/environments/DEV.postman_environment.json \
                        -r cli,json \
                        --reporter-json-export "reports/temp_report.json" || true

                    if [ -f reports/temp_report.json ]; then
                        jq --argfile input reports/temp_report.json '.results += $input.results' reports/final_results.json > reports/temp_merged.json
                        mv reports/temp_merged.json reports/final_results.json
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
                    npm install -g newman-reporter-html
                fi

                if [ ! -f /work/environments/DEV.postman_environment.json ]; then
                    echo "❌ Environment file not found! Cannot generate report."
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

        failure {
            echo '❌ Some tests failed. Check the reports.'
            emailext subject: "Postman Tests Failed", 
                    body: "Tests failed, check reports at Jenkins workspace.", 
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
        }
    }
}
