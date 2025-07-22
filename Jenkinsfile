pipeline {
  agent any

  environment {
    IMAGE_NAME = "avishkarlakade/resume-app"
    K8S_DIR = "k8s"

    // Credentials (already stored in Jenkins)
    DOCKERHUB = credentials('dockerhub-credentials')
    GITHUB_CREDS = credentials('github-credentials')
    KUBECONFIG_PATH = credentials('kubeconfig')
    DNSEXIT_API_KEY = credentials('dnsexit-api-key')
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/AvishkarLakade3119/ai-resume-builder.git',
            credentialsId: "${GITHUB_CREDS}"
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh 'docker build -t $IMAGE_NAME:latest .'
        }
      }
    }

    stage('Push to DockerHub') {
      steps {
        script {
          sh '''
            echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin
            docker push $IMAGE_NAME:latest
          '''
        }
      }
    }

    stage('Apply Kubernetes Secrets') {
      steps {
        script {
          sh "kubectl apply -f ${K8S_DIR}/secret.yaml --kubeconfig=${KUBECONFIG_PATH}"
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        script {
          sh """
            kubectl apply -f ${K8S_DIR}/deployment.yaml --kubeconfig=${KUBECONFIG_PATH}
            kubectl apply -f ${K8S_DIR}/service.yaml --kubeconfig=${KUBECONFIG_PATH}
          """
        }
      }
    }

    stage('Update DNS (DNSExit)') {
      steps {
        script {
          def ipCmd = "kubectl get svc resume-service --kubeconfig=${KUBECONFIG_PATH} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
          def externalIP = sh(script: ipCmd, returnStdout: true).trim()

          // If externalIP is empty (e.g. Minikube), fallback to NodePort IP from Minikube service command
          if (!externalIP) {
            externalIP = sh(script: "minikube service resume-service --url | sed -n 's|http://\\(.*\\):.*|\\1|p'", returnStdout: true).trim()
          }

          echo "External IP detected: ${externalIP}"

          sh """
            curl -X GET "https://update.dnsexit.com/RemoteUpdate.sv?login=lakadeavishkar@gmail.com&password=${DNSEXIT_API_KEY}&host=resumebuilder.publicvm.com&myip=${externalIP}"
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ Deployment successful! Visit: https://resumebuilder.publicvm.com"
    }
    failure {
      echo "❌ Deployment failed. Check Jenkins logs for details."
    }
  }
}
