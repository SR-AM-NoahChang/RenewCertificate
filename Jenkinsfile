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
                for file in collections/*.postman_collection.json; do
                    newman run "$file" -e environments/DEV.postman_environment.json \
                    -r cli,html \
                    --reporter-html-export "reports/$(basename "${file%.json}.html")"
                done
                set -e
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

        stage('Publish Test Reports') {
    steps {
        publishHTML(target: [
            reportDir: 'reports',       // 指定報告所在目錄
            reportFiles: '*.html',      // 匯出的 HTML 測試報告
            reportName: 'Postman Test Report',  // 在 Jenkins 介面顯示的名稱
            allowMissing: false,        // 如果報告不存在，是否允許
            alwaysLinkToLastBuild: false,  // 是否始終連結到最新的 Build
            keepAll: true               // 保留所有過往測試報告
        ])
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
