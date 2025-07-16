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
          COMMIT_HASH = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.IMAGE_TAG = COMMIT_HASH
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
        sh '''
          az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing

          # Replace image tag in deployment.yaml
          sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
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
