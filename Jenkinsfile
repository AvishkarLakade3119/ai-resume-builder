pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    GITHUB_CREDENTIALS = credentials('github-credentials')
    KUBECONFIG_CREDENTIALS = credentials('kubeconfig')
    DNSEXIT_API_KEY = credentials('dnsexit-api-key')
    IMAGE_NAME = "avishkarlakade/ai-resume-builder"
  }

  stages {
    stage('Clone Repo') {
      steps {
        git credentialsId: "${GITHUB_CREDENTIALS}", url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
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
          sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
          sh "docker push $IMAGE_NAME:latest"
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            sh '''
              export KUBECONFIG=$KUBECONFIG
              kubectl apply -f k8s/deployment-frontend.yaml
              kubectl apply -f k8s/service-frontend.yaml
            '''
          }
        }
      }
    }

    stage('Update DNSExit with External IP') {
      steps {
        script {
          withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            def externalIP = sh(script: "export KUBECONFIG=$KUBECONFIG && kubectl get svc resume-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
            echo "External IP: ${externalIP}"

            sh """
              curl -X POST "https://dynamicdnsv6.dnsexit.com/update.jsp?apikey=${DNSEXIT_API_KEY}&domain=resumebuilder.publicvm.com&ip=${externalIP}"
            """
          }
        }
      }
    }
  }
}
