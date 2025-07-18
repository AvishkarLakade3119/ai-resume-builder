pipeline {
  agent any

  environment {
    ACR_NAME       = 'avishkarairesume'
    IMAGE_NAME     = 'resume-app'
    RESOURCE_GROUP = 'poona_student'
    CLUSTER_NAME   = 'resumeCluster'
    DNS_HOST       = 'resumebuilder.publicvm.com'
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

    stage('Build & Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
          sh '''
            docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .
            echo $ACR_PASSWORD | docker login ${ACR_NAME}.azurecr.io -u $ACR_USERNAME --password-stdin
            docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy to AKS') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            echo "🔍 Verifying cluster..."
            kubectl config current-context
            kubectl get nodes
            kubectl wait node --all --for=condition=Ready --timeout=180s

            echo "📦 Updating deployment..."
            sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

            kubectl apply -f k8s/cluster-issuer.yaml || true
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml

            if [ -f k8s/ingress.yaml ]; then
              kubectl apply -f k8s/ingress.yaml
            fi

            echo "⏳ Waiting for rollout to complete..."
            kubectl rollout status deployment/${IMAGE_NAME} --timeout=180s
          '''
        }
      }
    }

    stage('Update DNSExit') {
      steps {
        withCredentials([
          file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE'),
          string(credentialsId: 'dnsexit-api-key', variable: 'DNS_API_KEY')
        ]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            echo "🌐 Fetching external IP of resume-service..."
            for i in {1..10}; do
              EXTERNAL_IP=$(kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
              if [ ! -z "$EXTERNAL_IP" ]; then
                echo "✅ Found External IP: $EXTERNAL_IP"
                break
              fi
              echo "🔁 Retry $i: Waiting for external IP..."
              sleep 15
            done

            if [ -z "$EXTERNAL_IP" ]; then
              echo "❌ ERROR: LoadBalancer IP not assigned. DNS update skipped."
              exit 1
            fi

            echo "🔁 Updating DNS record at DNSExit..."
            curl -s -X POST "https://api.dnsexit.com/dns/ud/" \
              -d "apikey=${DNS_API_KEY}" \
              -d "host=${DNS_HOST}" \
              -d "ip=${EXTERNAL_IP}"

            echo "✅ DNS record updated to $EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    success {
      echo '✅ SUCCESS: Deployed to AKS and DNS updated.'
    }
    failure {
      echo '❌ FAILURE: Check error logs.'
    }
  }
}
