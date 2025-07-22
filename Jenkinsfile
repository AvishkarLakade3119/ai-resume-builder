pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "avishkarlakade/ai-resume-builder:latest"
    DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
    GITHUB_CREDENTIALS = credentials('github-credentials')
    DNS_EXIT_API_KEY = credentials('dnsexit-api-key')
    KUBECONFIG = credentials('kubeconfig')
    SERVICE_NAME = "resume-service"
    DOMAIN = "resumebuilder.publicvm.com"
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

    stage('Login and Push to Docker Hub') {
      steps {
        sh '''
          echo "$DOCKER_HUB_CREDENTIALS_PSW" | docker login -u "$DOCKER_HUB_CREDENTIALS_USR" --password-stdin
          docker push $DOCKER_IMAGE
        '''
      }
    }

    stage('Configure Kubeconfig') {
      steps {
        writeFile file: 'kubeconfig', text: "${KUBECONFIG}"
        sh 'export KUBECONFIG=$WORKSPACE/kubeconfig'
      }
    }

    stage('Apply Kubernetes Manifests') {
      steps {
        sh 'kubectl apply -f k8s/'
      }
    }

    stage('Start Minikube Tunnel in Background') {
      steps {
        sh '''
          pkill -f "minikube tunnel" || true
          nohup minikube tunnel > tunnel.log 2>&1 &
          sleep 10
        '''
      }
    }

    stage('Wait for Service External IP') {
      steps {
        script {
          // Get Minikube IP
          def ip = sh(script: "minikube ip", returnStdout: true).trim()

          // Get NodePort for the service
          def port = sh(script: "kubectl get svc $SERVICE_NAME -o jsonpath='{.spec.ports[0].nodePort}'", returnStdout: true).trim()

          env.RESUME_IP = ip
          env.RESUME_PORT = port
          env.RESUME_URL = "http://${ip}:${port}"
          echo "🌐 Resume Builder App URL: ${env.RESUME_URL}"
        }
      }
    }

    stage('Update DNSExit Record') {
      steps {
        script {
          def response = sh(
            script: """
              curl -s -X POST "https://update.dnsexit.com/RemoteUpdate.sv" \\
              -d "login=${DNS_EXIT_API_KEY_USR}" \\
              -d "password=${DNS_EXIT_API_KEY_PSW}" \\
              -d "host=${DOMAIN}" \\
              -d "ip=${RESUME_IP}"
            """,
            returnStdout: true
          ).trim()
          echo "🔁 DNSExit Response: ${response}"
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completed. App available at: ${env.RESUME_URL}"
    }
    failure {
      echo "❌ Pipeline failed. Check tunnel.log or console output."
    }
  }
}
