pipeline {
  agent any

  environment {
    ACR_NAME = 'avishkarairesume'
    IMAGE_NAME = 'resume-app'
    RESOURCE_GROUP = 'poona_student'
    CLUSTER_NAME = 'resumeCluster'
    DNS_HOST = 'resumebuilder.publicvm.com'
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
        sh 'docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .'
      }
    }

    stage('Scan Docker Image') {
      steps {
        sh 'trivy image --exit-code 0 --severity MEDIUM,HIGH,CRITICAL ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}'
      }
    }

    stage('Login to ACR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
          sh 'echo $ACR_PASSWORD | docker login ${ACR_NAME}.azurecr.io -u $ACR_USERNAME --password-stdin'
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        sh 'docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}'
      }
    }

    stage('Deploy to AKS') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

            kubectl apply -f k8s/cluster-issuer.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml
            kubectl apply -f k8s/your-ingress-file.yaml

            if kubectl get deployment ${IMAGE_NAME}; then
              kubectl rollout status deployment/${IMAGE_NAME}
            else
              echo "⚠️ Deployment ${IMAGE_NAME} not found."
            fi
          '''
        }
      }
    }

    stage('Update DNS Record') {
      steps {
        withCredentials([
          file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE'),
          string(credentialsId: 'dnsexit-apikey', variable: 'DNS_API_KEY')
        ]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            EXTERNAL_IP=$(kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
            echo "AKS LoadBalancer IP: $EXTERNAL_IP"

            if [ -z "$EXTERNAL_IP" ]; then
              echo "❌ ERROR: LoadBalancer IP not yet assigned."
              exit 1
            fi

            curl -s "https://api.dnsexit.com/dns/ud/?apikey=${DNS_API_KEY}" -d "host=${DNS_HOST}&ip=$EXTERNAL_IP"

            echo "✅ DNS record for ${DNS_HOST} updated to → $EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    failure {
      echo '❌ Pipeline Failed!'
    }
    success {
      echo '✅ Build, Deploy & DNS Update Successful!'
    }
  }
}
