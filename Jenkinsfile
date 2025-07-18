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
        sh '''
          docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .
        '''
      }
    }

    stage('Scan Docker Image with Trivy') {
      steps {
        sh '''
          echo "🔍 Scanning image..."
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

    stage('Push Docker Image') {
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

            echo "✅ Verifying context and AKS readiness..."
            kubectl config current-context
            kubectl get nodes

            echo "⏳ Waiting for nodes..."
            kubectl wait --for=condition=Ready nodes --timeout=180s

            echo "🛠 Updating deployment image..."
            sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

            kubectl apply -f k8s/cluster-issuer.yaml || true
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml

            if [ -f k8s/ingress.yaml ]; then
              kubectl apply -f k8s/ingress.yaml
            fi

            echo "📦 Waiting for deployment rollout..."
            kubectl rollout status deployment/${IMAGE_NAME} --timeout=180s
          '''
        }
      }
    }

    stage('Update DNSExit with AKS IP') {
      steps {
        withCredentials([
          file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE'),
          string(credentialsId: 'dnsexit-api-key', variable: 'DNS_API_KEY')
        ]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            echo "🌐 Waiting for AKS LoadBalancer External IP..."

            # Wait for IP with retry
            for i in {1..10}; do
              EXTERNAL_IP=$(kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || echo "")
              if [ ! -z "$EXTERNAL_IP" ]; then
                break
              fi
              echo "🔄 Attempt $i: Still waiting for external IP..."
              sleep 15
            done

            if [ -z "$EXTERNAL_IP" ]; then
              echo "❌ AKS LoadBalancer External IP not available. Exiting."
              exit 1
            fi

            echo "✅ Found External IP: $EXTERNAL_IP"

            echo "🌐 Updating DNSExit..."
            RESPONSE=$(curl -s -X POST "https://api.dnsexit.com/dns/ud/" \
              -d "apikey=$DNS_API_KEY" \
              -d "host=$DNS_HOST" \
              -d "ip=$EXTERNAL_IP")

            echo "📨 DNSExit response: $RESPONSE"
            echo "✅ DNS update completed for $DNS_HOST → $EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "🎉 All steps completed: AKS deployed & DNS updated!"
    }
    failure {
      echo "❌ Pipeline failed. Check logs above for details."
    }
  }
}
