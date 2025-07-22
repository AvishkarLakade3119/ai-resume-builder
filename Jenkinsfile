pipeline {
  agent any

  environment {
    IMAGE_NAME = "avishkarlakade/resume-app"
    K8S_DIR = "k8s"

    DOCKERHUB = credentials('dockerhub-credentials')
    KUBECONFIG_PATH = credentials('kubeconfig')
    DNSEXIT_API_KEY = credentials('dnsexit-api-key')
  }

  stages {
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
          def externalIP = sh(
            script: "minikube service resume-service --url | sed -n 's|http://\\(.*\\):.*|\\1|p'",
            returnStdout: true
          ).trim()

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
