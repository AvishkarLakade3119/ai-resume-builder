pipeline {
  agent any

  environment {
    DOCKER_IMAGE = 'avishkarlakade/ai-resume-builder'
    KUBE_NAMESPACE = 'default'
    K8S_MANIFESTS_DIR = 'k8s'
    SERVICE_NAME = 'resume-service'
    DOMAIN_NAME = 'resumebuilder.publicvm.com'
    KUBECONFIG_PATH = 'kubeconfig'
  }

  stages {
    stage('Checkout') {
      steps {
        git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
      }
    }

    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker build -t $DOCKER_IMAGE .
            docker push $DOCKER_IMAGE
          '''
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            kubectl apply -f $K8S_MANIFESTS_DIR
          '''
        }
      }
    }

    stage('Wait for External IP') {
      steps {
        script {
          def maxRetries = 20
          def sleepSeconds = 15
          def externalIP = ""
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
            for (int i = 0; i < maxRetries; i++) {
              externalIP = sh(
                script: "KUBECONFIG=$KUBECONFIG_FILE kubectl get svc $SERVICE_NAME -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'",
                returnStdout: true
              ).trim()
              if (externalIP) {
                echo "External IP: $externalIP"
                break
              } else {
                echo "Waiting for External IP... (${i + 1}/$maxRetries)"
                sleep sleepSeconds
              }
            }
            if (!externalIP) {
              error("Failed to get External IP after ${maxRetries * sleepSeconds} seconds.")
            }
            env.EXTERNAL_IP = externalIP
          }
        }
      }
    }

    stage('Update DNSExit') {
      steps {
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNSEXIT_API_KEY')]) {
          sh '''
            curl -X GET "https://dynamicdnsexit.com/update?apikey=$DNSEXIT_API_KEY&hostname=$DOMAIN_NAME&myip=$EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ Deployment successful! Visit http://$DOMAIN_NAME"
    }
    failure {
      echo "❌ Deployment failed."
    }
  }
}
