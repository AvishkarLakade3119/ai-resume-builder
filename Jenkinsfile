pipeline {
  agent any

  environment {
    IMAGE_NAME = "avishkarlakade/ai-resume-builder"
    KUBECONFIG = credentials('kubeconfig')
  }

  stages {
    stage('Checkout Code') {
      steps {
        git credentialsId: 'github-credentials',
            url: 'https://github.com/AvishkarLakade3119/ai-resume-builder.git',
            branch: 'main'
      }
    }

    stage('Start Minikube Tunnel') {
      steps {
        script {
          sh 'pgrep -f "minikube tunnel" || nohup sudo minikube tunnel > /dev/null 2>&1 &'
          sleep 10
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
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push $IMAGE_NAME
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          kubectl apply -f k8s/
        '''
      }
    }

    stage('Wait for External IP') {
      steps {
        script {
          timeout(time: 3, unit: 'MINUTES') {
            waitUntil {
              script {
                def svc = sh(script: "kubectl get svc resume-service -o json", returnStdout: true).trim()
                def svcJson = readJSON text: svc
                def ip = svcJson.status.loadBalancer?.ingress?.getAt(0)?.ip
                if (ip) {
                  env.EXTERNAL_IP = ip
                  echo "External IP acquired: $EXTERNAL_IP"
                  return true
                } else {
                  echo "Waiting for external IP..."
                  return false
                }
              }
            }
          }
        }
      }
    }

    stage('Update DNS with DNSExit') {
      steps {
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNSEXIT_API_KEY')]) {
          sh '''
            curl -X POST "https://api.dnsexit.com/RemoteUpdate.sv" \
              -d "login=lakadeavishkar@gmail.com" \
              -d "password=$DNSEXIT_API_KEY" \
              -d "host=resumebuilder.publicvm.com" \
              -d "domain=publicvm.com" \
              -d "ip=$EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    failure {
      echo "❌ Pipeline failed."
    }
    success {
      echo "✅ Deployment completed successfully. Site: http://resumebuilder.publicvm.com"
    }
  }
}
