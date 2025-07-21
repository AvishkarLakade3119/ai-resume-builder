pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    KUBECONFIG_FILE = credentials('kubeconfig')
    DNSEXIT_API_KEY = credentials('dnsexit-api-key')
    DOMAIN_NAME = "resumebuilder.publicvm.com"
  }

  stages {
    stage('Build Docker Image') {
      steps {
        script {
          docker.build("avishkarlakade/ai-resume-builder:latest")
        }
      }
    }

    stage('Push Docker Image to DockerHub') {
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
            docker.image("avishkarlakade/ai-resume-builder:latest").push()
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_PATH')]) {
            sh '''
              mkdir -p ~/.kube
              cp $KUBECONFIG_PATH ~/.kube/config
              kubectl apply -f k8s/deployment.yaml
              kubectl apply -f k8s/service.yaml
            '''
          }
        }
      }
    }

    stage('Wait for External IP and Update DNS') {
      steps {
        script {
          sh '''
            echo "Waiting for External IP..."
            EXTERNAL_IP=""
            for i in {1..20}; do
              EXTERNAL_IP=$(kubectl get svc ai-resume-builder-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
              if [ "$EXTERNAL_IP" != "" ]; then
                break
              fi
              echo "Still waiting..."
              sleep 10
            done

            if [ "$EXTERNAL_IP" = "" ]; then
              echo "❌ Could not get External IP"
              exit 1
            fi

            echo "✅ External IP: $EXTERNAL_IP"
            echo "Updating DNSExit..."
            curl -X GET "https://api.dnsexit.com/RemoteUpdate.sv?login=$DOMAIN_NAME&password=$DNSEXIT_API_KEY&host=$DOMAIN_NAME&myip=$EXTERNAL_IP"
          '''
        }
      }
    }
  }

  post {
    success {
      echo '✅ Deployment Successful and DNS Updated!'
    }
    failure {
      echo '❌ Deployment Failed. Check the console for details.'
    }
  }
}
