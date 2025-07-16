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
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          set -e
          echo "Building Docker image..."
          docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:latest .
        '''
      }
    }

    stage('Login to ACR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
          sh '''
            set -e
            echo "Logging into Azure Container Registry..."
            echo $ACR_PASSWORD | docker login ${ACR_NAME}.azurecr.io -u $ACR_USERNAME --password-stdin
          '''
        }
      }
    }

    stage('Push Image to ACR') {
      steps {
        sh '''
          set -e
          echo "Pushing Docker image to ACR..."
          docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Deploy to AKS') {
      steps {
        sh '''
          set -e
          echo "Getting AKS credentials..."
          az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing

          echo "Applying Kubernetes manifests..."
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml

          echo "Checking rollout status..."
          kubectl rollout status deployment/${IMAGE_NAME}
        '''
      }
    }
  }

  post {
    failure {
      echo '🚨 Pipeline failed! Check logs above.'
    }
    success {
      echo '✅ Deployment successful!'
    }
  }
}
