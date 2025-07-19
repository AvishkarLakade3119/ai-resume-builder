pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'avishkarlakade'
    IMAGE_NAME     = 'resume-app'
    REPO_NAME      = "${DOCKERHUB_USER}/${IMAGE_NAME}"
    DNS_HOST       = 'resumebuilder.publicvm.com'
  }

  stages {

    stage('Checkout Source') {
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
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
          sh '''
            echo "🛠️ Building Docker image..."
            docker build -t $REPO_NAME:$IMAGE_TAG .

            echo "🔐 Logging into Docker Hub..."
            echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin

            echo "📦 Pushing image to Docker Hub..."
            docker push $REPO_NAME:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE

            echo "🔧 Updating image in deployment..."
            sed -i "s|image: .*|image: $REPO_NAME:$IMAGE_TAG|g" k8s/deployment.yaml

            echo "🚀 Applying Kubernetes resources..."
            kubectl apply -f k8s/cluster-issuer.yaml || true
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml
            [ -f k8s/ingress.yaml ] && kubectl apply -f k8s/ingress.yaml

            echo "⏳ Waiting for rollout to complete..."
            kubectl rollout status deployment/$IMAGE_NAME --timeout=180s
          '''
        }
      }
    }

    stage('Wait for External IP') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          script {
            def maxRetries = 12
            def externalIP = ""
            for (int i = 1; i <= maxRetries; i++) {
              externalIP = sh(
                script: '''
                  export KUBECONFIG=$KUBECONFIG_FILE
                  kubectl get svc resume-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>/dev/null || true
                ''',
                returnStdout: true
              ).trim()

              if (externalIP) {
                echo "✅ External IP assigned: ${externalIP}"
                break
              } else {
                echo "🔄 Attempt ${i}/${maxRetries}: Waiting for external IP..."
                sleep 15
              }
            }

            if (!externalIP) {
              error("❌ ERROR: External IP not assigned after 3 minutes.")
            }

            env.RESUME_APP_EXTERNAL_IP = externalIP
          }
        }
      }
    }

    stage('Update DNS Record') {
      steps {
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNS_API_KEY')]) {
          sh '''
            echo "🌐 Updating DNS: $DNS_HOST → $RESUME_APP_EXTERNAL_IP"
            curl -s -X POST "https://api.dnsexit.com/dns/ud/" \
              -d "apikey=$DNS_API_KEY" \
              -d "host=$DNS_HOST" \
              -d "ip=$RESUME_APP_EXTERNAL_IP"

            echo "✅ DNS record updated!"
          '''
        }
      }
    }

    stage('Apply SSL Certificate') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            echo "🔐 Applying certificate.yaml..."
            kubectl apply -f k8s/certificate.yaml
          '''
        }
      }
    }
  }

  post {
    success {
      echo '✅ Deployment complete: DockerHub → Minikube → DNS → SSL'
    }
    failure {
      echo '❌ Pipeline failed. Please check the logs above.'
    }
  }
}
