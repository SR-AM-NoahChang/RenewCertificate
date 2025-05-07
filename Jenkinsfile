pipeline {
    agent any
    environment {
        // 設定環境變數，指向容器中的工作目錄
        ENV_DIR = '/work/environments'
        COLLECTIONS_DIR = '/work/collections'
        REPORTS_DIR = '/work/reports'
    }
    stages {
        stage('Check Environment and Collections') {
            steps {
                script {
                    // 檢查 environments 目錄是否存在，並列出文件
                    echo 'Checking environment files...'
                    sh 'ls -lh /work/environments'
                    
                    // 檢查 collections 目錄是否存在，並列出文件
                    echo 'Checking Postman collections...'
                    sh 'ls -lh /work/collections'
                }
            }
        }
        stage('Run Postman Collections') {
            steps {
                script {
                    echo 'Running Postman collections...'
                    // 執行 Postman collections 並生成 JSON 報告
                    sh '''
                    newman run /work/collections/*.postman_collection.json \
                    -e /work/environments/DEV.postman_environment.json \
                    -r cli,json \
                    --reporter-json-export /work/reports/temp_report.json
                    '''
                }
            }
        }
        stage('Merge JSON Results') {
            steps {
                script {
                    echo 'Merging JSON results...'
                    // 使用 jq 合併報告結果
                    sh '''
                    jq --argfile input /work/reports/temp_report.json '.results += $input.results' /work/reports/final_results.json
                    mv /work/reports/temp_report.json /work/reports/final_results.json
                    '''
                }
            }
        }
        stage('Generate Consolidated HTML Report') {
            steps {
                script {
                    echo 'Generating consolidated HTML report...'
                    // 生成最終的 HTML 報告
                    sh '''
                    newman run /work/collections/*.postman_collection.json \
                    -e /work/environments/DEV.postman_environment.json \
                    -r html \
                    --reporter-html-export /work/reports/FinalReport.html
                    '''
                }
            }
        }
        stage('Publish Test Reports') {
            steps {
                script {
                    echo 'Publishing test reports...'
                    // 將 HTML 報告發佈到 Jenkins
                    publishHTML(target: [
                        reportName: 'Postman Test Report',
                        reportDir: '/work/reports',
                        reportFiles: 'FinalReport.html',
                        keepAll: true
                    ])
                }
            }
        }
    }
    post {
        always {
            // 清理工作目錄中的報告
            echo 'Cleaning up...'
            sh 'rm -rf /work/reports/*'
        }
        success {
            echo 'Test run completed successfully!'
        }
        failure {
            echo 'Test run failed. Check the logs and reports.'
        }
    }
}
