pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "avishkarlakade/ai-resume-builder:latest"
    KUBECONFIG = "$HOME/.kube/config"
    DEPLOYMENT_YAML = "k8s/deployment.yaml"
    SERVICE_YAML = "k8s/service.yaml"
    DNS_EXIT_API = "https://api.dnsexit.com/RemoteUpdate.sv"
    DNS_EXIT_HOSTNAME = "yourdomain.com"
    DNS_EXIT_API_KEY = credentials('dnsexit-api-key') // must be added in Jenkins credentials
  }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DOCKER_IMAGE .'
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASS')]) {
          sh """
            echo "$DOCKER_HUB_PASS" | docker login -u "$DOCKER_HUB_USER" --password-stdin
            docker push $DOCKER_IMAGE
          """
        }
      }
    }

    stage('Apply Kubernetes YAMLs') {
      steps {
        sh """
          kubectl apply -f $DEPLOYMENT_YAML
          kubectl apply -f $SERVICE_YAML
        """
      }
    }

    stage('Wait for Service IP') {
      steps {
        script {
          def retries = 10
          def externalIP = ""
          for (int i = 0; i < retries; i++) {
            externalIP = sh(script: "kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
            if (externalIP) {
              break
            }
            echo "Waiting for External IP..."
            sleep(10)
          }
          if (!externalIP) {
            // fallback to NodePort external IP (manual retrieval from minikube)
            externalIP = sh(script: "minikube ip", returnStdout: true).trim()
          }
          env.RESUME_APP_EXTERNAL_IP = externalIP
        }
      }
    }

    stage('Update DNSExit Record') {
      steps {
        sh """
          curl -X GET "$DNS_EXIT_API?login=${DNS_EXIT_API_KEY_USR}&password=${DNS_EXIT_API_KEY_PSW}&host=${DNS_EXIT_HOSTNAME}&myip=$RESUME_APP_EXTERNAL_IP"
        """
      }
    }
  }

  post {
    success {
      echo "✅ Deployment complete! App available at http://$RESUME_APP_EXTERNAL_IP:30080"
    }
    failure {
      echo "❌ Deployment failed. Check pipeline logs."
    }
  }
}
