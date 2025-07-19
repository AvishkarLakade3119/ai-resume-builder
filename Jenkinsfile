pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "avishkarlakade/ai-resume-builder:latest"
    DOMAIN_NAME = "resuemebuilder.publicvm.com"
  }

  stages {
    stage('Clone Repo') {
      steps {
        git 'https://github.com/AvishkarLakade3119/ai-resume-builder.git'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DOCKER_IMAGE .'
      }
    }

    stage('Push to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push $DOCKER_IMAGE
          '''
        }
      }
    }

    stage('Configure kubeconfig') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            kubectl config use-context minikube
          '''
        }
      }
    }

    stage('Deploy to Minikube') {
      steps {
        sh '''
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
        '''
      }
    }

    stage('Get Minikube External IP & Update DNS') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE'),
                         string(credentialsId: 'dnsexit-api-key', variable: 'EXITDNS_KEY')]) {
          script {
            def serviceUrl = ""
            timeout(time: 2, unit: 'MINUTES') {
              waitUntil {
                serviceUrl = sh(script: "minikube service resume-builder-service --url | tail -1", returnStdout: true).trim()
                return serviceUrl != ""
              }
            }

            echo "Service URL: ${serviceUrl}"
            def ipOnly = serviceUrl.replaceFirst(/^https?:\\/\\//, "").split(":")[0]

            echo "Resolved IP: ${ipOnly}"

            sh """
              curl -s "https://api.exitdns.com/nic/update?hostname=$DOMAIN_NAME&myip=${ipOnly}&apikey=$EXITDNS_KEY"
            """
          }
        }
      }
    }
  }
}
