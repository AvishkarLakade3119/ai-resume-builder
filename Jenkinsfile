pipeline {
  agent any

  environment {
    ACR_NAME = 'avishkarairesume'
    IMAGE_NAME = 'resume-app'
    RESOURCE_GROUP = 'poona_student'
    CLUSTER_NAME = 'resumeCluster'
    DNS_API_KEY = 'ULrX68133L29lwW5fZc7ccLW62r7Sd' // 🔐 Use Jenkins secret for security
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

            # Replace image tag in deployment.yaml
            sed -i "s|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:.*|image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml

            # Apply Kubernetes manifests
            kubectl apply -f k8s/cluster-issuer.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml
            kubectl apply -f k8s/your-ingress-file.yaml

            # Wait for rollout
            kubectl rollout status deployment/${IMAGE_NAME}
          '''
        }
      }
    }

    stage('Update DNS Record') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            echo "🌐 Fetching external IP of LoadBalancer service..."
            EXTERNAL_IP=$(kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

            if [ -z "$EXTERNAL_IP" ]; then
              echo "❌ External IP not available yet. Aborting DNS update."
              exit 1
            fi

            echo "🔁 Found LoadBalancer IP: $EXTERNAL_IP"
            echo "🌍 Updating DNS A record via DNSExit..."

            RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/dns_result.txt "https://api.dnsexit.com/dns/ud/?apikey=${DNS_API_KEY}" -d "host=${DNS_HOST}&ip=$EXTERNAL_IP")

            if [ "$RESPONSE" -ne 200 ]; then
              echo "❌ DNS update failed. Response code: $RESPONSE"
              cat /tmp/dns_result.txt
              exit 1
            fi

            echo "✅ DNS A record updated: ${DNS_HOST} → $EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    failure {
      echo '🚨 Pipeline failed! Check logs above.'
    }
    success {
      echo '✅ Deployment + DNS update successful!'
    }
  }
}
