pipeline {
  agent any

  environment {
    IMAGE_NAME = 'avishkarlakade/ai-resume-builder'
    KUBE_CONFIG = credentials('kubeconfig')
  }

  stages {
    stage('Checkout Code') {
      steps {
        git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder.git'
      }
    }

    stage('Start Minikube Tunnel') {
      steps {
        script {
          sh '''
            if ! pgrep -f "minikube tunnel" > /dev/null; then
              echo "🔁 Starting minikube tunnel..."
              nohup sudo minikube tunnel > tunnel.log 2>&1 &
              sleep 10
            else
              echo "✅ Minikube tunnel already running."
            fi
          '''
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE_NAME .'
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $IMAGE_NAME
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            kubectl set image deployment/resume-app resume-app=$IMAGE_NAME --namespace=default || kubectl apply -f k8s/
          '''
        }
      }
    }

    stage('Wait for External IP') {
      steps {
        script {
          env.EXTERNAL_IP = ''
          timeout(time: 2, unit: 'MINUTES') {
            waitUntil {
              env.EXTERNAL_IP = sh(
                script: "kubectl get svc resume-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' | tr -d \"'\"",
                returnStdout: true
              ).trim()
              return env.EXTERNAL_IP != ""
            }
          }
          echo "🌐 External IP allocated: ${env.EXTERNAL_IP}"
        }
      }
    }

    stage('Update DNS with DNSExit') {
      steps {
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNSEXIT_API_KEY')]) {
          sh '''
            curl -X GET "https://update.dnsexit.com/RemoteUpdate.sv?login=lakadeavishkar@gmail.com&password=${DNSEXIT_API_KEY}&host=resumebuilder.publicvm.com&myip=${EXTERNAL_IP}"
          '''
        }
      }
    }
  }

  post {
    success {
      echo '✅ CI/CD pipeline completed successfully.'
    }
    failure {
      echo '❌ Pipeline failed.'
    }
  }
}
