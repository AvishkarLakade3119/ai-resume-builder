pipeline {
  agent any

  environment {
    IMAGE_NAME = "avishkarlakade/ai-resume-builder"
    IMAGE_TAG = "latest"
    K8S_NAMESPACE = "default"
    DEPLOYMENT_NAME = "resume-deployment"
    SERVICE_NAME = "resume-service"
    DOMAIN = "resumebuilder.publicvm.com"
    KUBECONFIG_CREDENTIALS = credentials('kubeconfig')
    DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    DNS_API_KEY = credentials('dnsexit-api-key')
  }

  stages {
    stage('Checkout') {
      steps {
        git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder', branch: 'main'
      }
    }

    stage('Docker Build & Push') {
      steps {
        withDockerRegistry(credentialsId: 'dockerhub-credentials', url: '') {
          sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
          sh 'docker push $IMAGE_NAME:$IMAGE_TAG'
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            kubectl apply -f k8s/
          '''
        }
      }
    }

    stage('Wait for External IP') {
      steps {
        script {
          def externalIP = ""
          timeout(time: 3, unit: 'MINUTES') {
            waitUntil {
              def svc = sh(script: '''
                export KUBECONFIG=$KUBECONFIG_FILE
                kubectl get svc $SERVICE_NAME --output=jsonpath="{.status.loadBalancer.ingress[0].ip}"
              ''', returnStdout: true).trim()

              if (svc && svc != "") {
                externalIP = svc
                env.EXTERNAL_IP = externalIP
                return true
              }
              return false
            }
          }
          echo "🔗 External IP is: ${env.EXTERNAL_IP}"
        }
      }
    }

    stage('Update DNSExit') {
      steps {
        sh '''
          curl -X GET "https://dynamicdnsexit.com/dnsupdate.php?\
          hostname=$DOMAIN&myip=$EXTERNAL_IP&token=$DNS_API_KEY"
        '''
      }
    }
  }

  post {
    failure {
      echo "❌ Deployment failed."
    }
    success {
      echo "✅ Successfully deployed to http://$DOMAIN"
    }
  }
}
