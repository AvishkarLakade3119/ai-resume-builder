pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "avishkarlakade/ai-resume-builder:latest"
    REGISTRY_CREDENTIALS = credentials('dockerhub-credentials')
    DNS_EXIT_API_KEY = credentials('dnsexit-api-key')
    GITHUB_CREDENTIALS = credentials('github-credentials')
    KUBECONFIG_CRED = credentials('kubeconfig') // Use Secret File type in Jenkins
  }

  stages {
    stage('Checkout Code') {
      steps {
        git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder', branch: 'main'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DOCKER_IMAGE .'
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withDockerRegistry([credentialsId: 'dockerhub-credentials', url: '']) {
          sh 'docker push $DOCKER_IMAGE'
        }
      }
    }

    stage('Set KUBECONFIG') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            mkdir -p ~/.kube
            cp $KUBECONFIG_FILE ~/.kube/config
            chmod 600 ~/.kube/config
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          kubectl delete deploy resume-deployment --ignore-not-found
          kubectl apply -f k8s/
        '''
      }
    }

    stage('Wait for External IP') {
      steps {
        script {
          def maxRetries = 20
          def sleepTime = 15
          def externalIP = ""

          for (int i = 0; i < maxRetries; i++) {
            externalIP = sh(script: "kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
            if (externalIP && externalIP != "''") {
              break
            }
            echo "Waiting for External IP allocation... ($i/$maxRetries)"
            sleep sleepTime
          }

          if (!externalIP || externalIP == "''") {
            error("Failed to get External IP")
          }

          env.EXTERNAL_IP = externalIP
          echo "External IP is: ${externalIP}"
        }
      }
    }

    stage('Update DNSExit') {
      steps {
        sh '''
          curl -X POST "https://dynamicdns.park-your-domain.com/update?host=resumebuilder&domain=publicvm.com&password=$DNS_EXIT_API_KEY&ip=$EXTERNAL_IP"
        '''
      }
    }
  }

  post {
    failure {
      echo "Build or deployment failed!"
    }
    success {
      echo "✅ App deployed successfully at http://resumebuilder.publicvm.com"
    }
  }
}
