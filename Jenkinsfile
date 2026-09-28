pipeline {
    agent any

    environment {
        AWS_REGION       = 'us-east-2'
        AWS_ACCOUNT_ID   = '<your-aws-account-id>'
        ECR_REGISTRY     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FRONTEND_REPO    = 'techchallenge1-frontend'
        BACKEND_REPO     = 'techchallenge1-backend'
        ECS_CLUSTER      = 'techchallenge1-cluster'
        FRONTEND_SERVICE = 'techchallenge1-frontend-service'
        BACKEND_SERVICE  = 'techchallenge1-backend-service'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Images') {
            steps {
                sh '''
                    docker build -t ${FRONTEND_REPO}:latest ./frontend
                    docker build -t ${BACKEND_REPO}:latest ./backend
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        docker tag ${FRONTEND_REPO}:latest ${ECR_REGISTRY}/${FRONTEND_REPO}:latest
                        docker tag ${BACKEND_REPO}:latest ${ECR_REGISTRY}/${BACKEND_REPO}:latest

                        docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:latest
                        docker push ${ECR_REGISTRY}/${BACKEND_REPO}:latest
                    '''
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        aws ecs update-service --cluster ${ECS_CLUSTER} --service ${FRONTEND_SERVICE} --force-new-deployment --region ${AWS_REGION}
                        aws ecs update-service --cluster ${ECS_CLUSTER} --service ${BACKEND_SERVICE} --force-new-deployment --region ${AWS_REGION}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check stage logs above for details.'
        }
    }
}