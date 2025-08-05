pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    GITHUB_CREDENTIALS = credentials('github-credentials')
    DNS_EXIT_API_KEY = credentials('dnsexit-api-key')
    KUBECONFIG_CREDENTIALS = credentials('kubeconfig')
    IMAGE_NAME = "avishkarlakade/resumecraft:latest"
  }

  stages {
    stage('Checkout') {
      steps {
        git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh 'docker build -t $IMAGE_NAME .'
        }
      }
    }

    stage('Push to DockerHub') {
      steps {
        script {
          sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
          sh 'docker push $IMAGE_NAME'
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        script {
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
            sh '''
              export KUBECONFIG=$KUBECONFIG_FILE
              kubectl apply -f k8s/deployment.yaml
              kubectl apply -f k8s/service.yaml
            '''
          }
        }
      }
    }

    stage('Update DNS Record') {
      steps {
        script {
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
            sh '''
              export KUBECONFIG=$KUBECONFIG_FILE
              IP=""
              for i in {1..10}; do
                IP=$(kubectl get svc resume-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
                if [ ! -z "$IP" ]; then break; fi
                echo "Waiting for external IP..."; sleep 10
              done

              if [ -z "$IP" ]; then
                echo "External IP not assigned."; exit 1
              fi

              curl -X POST "https://api.dnsexit.com/RemoteUpdate.sv" \
                -d "login=avishkarlakade&password=$DNS_EXIT_API_KEY&host=resumebuilder&domain=publicvm.com&ip=$IP"
            '''
          }
        }
      }
    }
  }
}
