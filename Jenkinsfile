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

            echo "📄 Checking kube context..."
            kubectl config current-context || { echo "❌ Invalid kubeconfig or context!"; exit 1; }

            echo "⏳ Waiting for AKS nodes to become Ready..."
            kubectl wait --for=condition=Ready nodes --timeout=180s || {
              echo "❌ AKS nodes not ready!"; exit 1;
            }

            echo "🔧 Updating image tag in deployment.yaml..."
            sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

            echo "🚀 Applying manifests to AKS..."
            kubectl apply -f k8s/cluster-issuer.yaml || true
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml

            if [ -f k8s/ingress.yaml ]; then
              kubectl apply -f k8s/ingress.yaml
            else
              echo "⚠️ No ingress.yaml found. Skipping..."
            fi

            echo "📦 Waiting for deployment rollout..."
            kubectl rollout status deployment/${IMAGE_NAME} --timeout=180s || {
              echo "❌ Deployment rollout failed"; exit 1;
            }
          '''
        }
      }
    }

    stage('Update DNSExit Record') {
      steps {
        withCredentials([
          file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE'),
          string(credentialsId: 'dnsexit-api-key', variable: 'DNS_API_KEY')
        ]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            echo "🌐 Getting AKS LoadBalancer External IP..."
            EXTERNAL_IP=""
            for i in {1..10}; do
              EXTERNAL_IP=$(kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
              if [ -n "$EXTERNAL_IP" ]; then
                break
              fi
              echo "⏳ Waiting for External IP to be assigned... ($i)"
              sleep 15
            done

            if [ -z "$EXTERNAL_IP" ]; then
              echo "❌ Failed to fetch External IP. Skipping DNS update."
              exit 1
            fi

            echo "✅ Found External IP: $EXTERNAL_IP"

            echo "🔁 Updating DNSExit with AKS IP..."
            curl -X POST "https://api.dnsexit.com/dns/ud/" \
              -d "apikey=$DNS_API_KEY" \
              -d "host=resumebuilder.publicvm.com" \
              -d "ip=$EXTERNAL_IP"

            echo "✅ DNS record updated to point to $EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    failure {
      echo '🚨 Pipeline failed! Check logs for errors.'
    }
    success {
      echo '✅ Deployment and DNS update completed successfully!'
    }
  }
}
