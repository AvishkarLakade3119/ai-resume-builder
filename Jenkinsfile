pipeline {
  agent any

  environment {
    IMAGE_NAME = "avishkarlakade/ai-resume-builder"
    IMAGE_TAG = "latest"
    K8S_DIR = "k8s"
    SERVICE_NAME = "resume-service"
    DOMAIN = "resumebuilder.publicvm.com"
    DNS_EXIT_API_KEY = credentials('dnsexit-api-key')
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/AvishkarLakade3119/ai-resume-builder.git', branch: 'main'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push $IMAGE_NAME:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            kubectl apply -f $K8S_DIR/deployment.yaml
            kubectl apply -f $K8S_DIR/service.yaml
          '''
        }
      }
    }

    stage('Update DNSExit IP') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          script {
            def serviceUrl = sh(script: "minikube service $SERVICE_NAME --url", returnStdout: true).trim()
            echo "Service URL: ${serviceUrl}"

            def serviceIP = sh(script: "echo '${serviceUrl}' | sed -E 's|http://([^:/]+).*|\\1|'", returnStdout: true).trim()
            echo "Extracted IP: ${serviceIP}"

            if (serviceIP) {
              sh """
                curl -X GET "https://update.dnsexit.com/RemoteUpdate.sv?login=avishkarlakade&password=$DNS_EXIT_API_KEY&host=$DOMAIN&myip=${serviceIP}"
              """
            } else {
              error("Failed to retrieve service IP from Minikube")
            }
          }
        }
      }
    }
  }
}
