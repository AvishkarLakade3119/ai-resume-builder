pipeline {
  agent any

  environment {
    IMAGE_NAME = 'avishkarlakade/ai-resume-builder'
    IMAGE_TAG = 'latest'
    DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
    DNS_EXIT_API_KEY = credentials('dnsexit-api-key')
  }

  triggers {
    githubPush()
  }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
      }
    }

    stage('Push Docker Image to Docker Hub') {
      steps {
        withDockerRegistry([ credentialsId: 'dockerhub-credentials', url: '' ]) {
          sh 'docker push $IMAGE_NAME:$IMAGE_TAG'
        }
      }
    }

    stage('Deploy to Minikube (Kubernetes)') {
      steps {
        sh '''
        mkdir -p ~/.kube
        echo "$KUBECONFIG" > ~/.kube/config
        chmod 600 ~/.kube/config

        kubectl delete -f k8s/ --ignore-not-found
        kubectl apply -f k8s/
        '''
      }
    }

    stage('Expose External IP & Update DNSExit') {
      steps {
        script {
          def externalIP = sh(script: "kubectl get svc resume-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' || kubectl get svc resume-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}' || kubectl get svc resume-service -o=jsonpath='{.status.loadBalancer.ingress[0].*}' || kubectl get svc resume-service -o=jsonpath='{.status.loadBalancer.ingress[0]}'", returnStdout: true).trim()
          if (!externalIP) {
            externalIP = sh(script: "kubectl get svc resume-service -o=jsonpath='{.spec.clusterIP}'", returnStdout: true).trim()
          }

          echo "External IP detected: ${externalIP}"

          def updateDnsCommand = """
          curl -X POST "https://www.dnsexit.com/RemoteUpdate.sv" \\
            -d "login=username" \\
            -d "password=$DNS_EXIT_API_KEY" \\
            -d "host=resumebuilder" \\
            -d "domain=publicvm.com" \\
            -d "ip=${externalIP}"
          """

          sh updateDnsCommand
        }
      }
    }
  }

  post {
    failure {
      echo '❌ Build failed!'
    }
    success {
      echo '✅ CI/CD Pipeline completed successfully!'
    }
  }
}
