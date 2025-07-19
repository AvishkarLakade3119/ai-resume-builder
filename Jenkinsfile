pipeline {
    agent any

    environment {
        IMAGE_NAME = "resume-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        ACR_LOGIN_SERVER = "avishkarairesume.azurecr.io"
        KUBE_NAMESPACE = "default"
        DEPLOYMENT_NAME = "resume-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/avishkar-ai/ai-resume-builder.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        stage('Push to ACR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'acr-credentials', // Store this in Jenkins Credentials
                    passwordVariable: 'ACR_PASSWORD',
                    usernameVariable: 'ACR_USERNAME'
                )]) {
                    sh """
                        docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG
                        echo $ACR_PASSWORD | docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME --password-stdin
                        docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'minikube-kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        sed -i 's|IMAGE_TAG|$IMAGE_TAG|g' k8s/deployment.yaml
                        kubectl apply -f k8s/
                        kubectl rollout status deployment/$DEPLOYMENT_NAME
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment to Minikube successful!'
        }
        failure {
            echo '❌ Deployment failed. Please check the logs.'
        }
    }
}
