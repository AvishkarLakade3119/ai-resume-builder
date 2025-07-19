pipeline {
  agent any

  environment {
    // DockerHub credentials
    DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
    // Kubeconfig file for kubectl
    KUBECONFIG_FILE = credentials('kubeconfig')
    // Image details
    IMAGE_NAME = "avishkarlakade/ai-resume-builder"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout Source') {
      steps {
        checkout scm
      }
    }

    stage('Docker Build') {
      steps {
        script {
          sh """
            docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          """
        }
      }
    }

    stage('Docker Login & Push') {
      steps {
        script {
          sh """
            echo "${DOCKER_CREDENTIALS_PSW}" | docker login -u "${DOCKER_CREDENTIALS_USR}" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withEnv(["KUBECONFIG=$KUBECONFIG_FILE"]) {
          // Optionally update image if already deployed
          sh """
            kubectl apply -f k8s/
            # OR: uncomment the below if you just want to update the image in a running deployment
            # kubectl set image deployment/ai-resume-builder ai-resume-builder=${IMAGE_NAME}:${IMAGE_TAG} --record
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ Successfully built and deployed: ${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo "❌ Build or deployment failed!"
    }
    always {
      cleanWs()
      sh 'docker image prune -f'
    }
  }
}
