pipeline {
  agent any

  environment {
    ACR_NAME = 'avishkarairesume'
    IMAGE_NAME = 'resume-app'
    RESOURCE_GROUP = 'poona_student'
    CLUSTER_NAME = 'resumeCluster'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            credentialsId: 'github-credentials',
            url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
        script {
          env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .
        '''
      }
    }

    stage('Scan Docker Image with Trivy') {
      steps {
        sh '''
          echo "🔍 Running Trivy scan..."
          trivy image --exit-code 0 --severity MEDIUM,HIGH,CRITICAL ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
        '''
      }
    }

    stage('Login to ACR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
          sh '''
            echo $ACR_PASSWORD | docker login ${ACR_NAME}.azurecr.io -u $ACR_USERNAME --password-stdin
          '''
        }
      }
    }

    stage('Push Image to ACR') {
      steps {
        sh '''
          docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
        '''
      }
    }

    stage('Deploy to AKS') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            # Update image tag in deployment file
            sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

            kubectl apply -f k8s/cluster-issuer.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml

            # Optional: apply ingress if present
            if [ -f k8s/ingress.yaml ]; then
              kubectl apply -f k8s/ingress.yaml
            else
              echo "⚠️ ingress.yaml not found. Skipping ingress setup."
            fi

            # Wait for rollout to finish
            if kubectl get deployment ${IMAGE_NAME}; then
              kubectl rollout status deployment/${IMAGE_NAME}
            else
              echo "⚠️ Deployment ${IMAGE_NAME} not found. Skipping rollout wait."
            fi
          '''
        }
      }
    }
  }

  post {
    failure {
      echo '🚨 Pipeline failed! Check logs for details.'
    }
    success {
      echo '✅ Deployment to AKS successful!'
    }
  }
}
