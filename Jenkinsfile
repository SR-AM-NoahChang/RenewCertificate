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
                    sh 'docker build -t newman-runner -f Dockerfile.newman .'
                }
            }
        }

        stage('Run All Postman Collections') {
            steps {
                script {
                    docker.image(DOCKER_IMAGE).inside("-v ${env.WORKSPACE}:/work -w /work") {
                        sh '''
                            mkdir -p reports

                            for file in collections/*.json; do
                                echo "➡️ Running collection: $file"
                                base=$(basename "$file" .json)

                                # 將檔名轉為安全的英文名（避免 Jenkins HTML plugin 報錯）
                                safe_name=$(echo "$base" | iconv -f utf8 -t ascii//translit | tr -cd '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')
                                report_file="reports/${safe_name}.html"

                                echo "📝 Saving report as: $report_file"

                                newman run "$file" -e environments/DEV.postman_environment.json \
                                    -r html --reporter-html-export "$report_file"
                            done
                        '''
                    }
                }
            }
        }

        stage('Publish HTML Reports') {
            steps {
                publishHTML(target: [
                    reportDir: 'reports',
                    reportFiles: '*.html',
                    reportName: 'Postman API Test Reports'
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
            echo '❌ Some collections failed. Please check the reports.'
        }
    }
}
