pipeline {
  agent any

  environment {
    DOCKER_IMAGE = 'avishkarlakade3119/ai-resume-builder'
    K8S_DEPLOYMENT = 'resume-deployment'
    K8S_SERVICE = 'resume-service'
    K8S_NAMESPACE = 'default'
    GITHUB_REPO = 'https://github.com/AvishkarLakade3119/ai-resume-builder.git'
    BRANCH = 'main'
  }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: "${BRANCH}",
            credentialsId: 'github-credentials',
            url: "${GITHUB_REPO}"
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          docker.build("${DOCKER_IMAGE}:latest")
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          script {
            sh """
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
              docker push ${DOCKER_IMAGE}:latest
            """
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          withEnv(["KUBECONFIG=$KUBECONFIG_FILE"]) {
            sh """
              kubectl apply -f k8s/
            """
          }
        }
      }
    }

    stage('Wait for External IP') {
      steps {
        script {
          timeout(time: 2, unit: 'MINUTES') {
            waitUntil {
              script {
                def externalIp = sh(
                  script: "kubectl get svc ${K8S_SERVICE} -n ${K8S_NAMESPACE} --output=jsonpath='{.status.loadBalancer.ingress[0].ip}'",
                  returnStdout: true
                ).trim()

                if (externalIp == '' || externalIp == 'null') {
                  echo "Waiting for External IP..."
                  return false
                } else {
                  env.EXTERNAL_IP = externalIp
                  echo "External IP acquired: ${externalIp}"
                  return true
                }
              }
            }
          }
        }
      }
    }

    stage('Update DNS via DNSExit API') {
      steps {
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNS_API_KEY')]) {
          script {
            def domain = "resumebuilder.publicvm.com"
            def ip = env.EXTERNAL_IP
            def updateCmd = """
              curl -X GET "https://api.dnsexit.com/RemoteUpdate.sv?login=lakadeavishkar&password=${DNS_API_KEY}&host=resume&domain=publicvm.com&ip=${ip}"
            """
            sh updateCmd
            echo "DNS updated for ${domain} -> ${ip}"
          }
        }
      }
    }
  }

  post {
    failure {
      echo '❌ Build failed. Check the logs for details.'
    }
    success {
      echo "✅ Deployment successful! App is live at: http://resumebuilder.publicvm.com"
    }
  }
}
