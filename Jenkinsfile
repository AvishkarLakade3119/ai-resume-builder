pipeline {
  agent any

  environment {
    GIT_REPO = 'https://github.com/AvishkarLakade3119/ai-resume-builder.git'
    GIT_BRANCH = 'main'
    DOCKER_IMAGE = 'avishkarlakade/ai-resume-builder:latest'
  }

  stages {
    stage('Checkout SCM') {
      steps {
        git(
          url: env.GIT_REPO,
          branch: env.GIT_BRANCH,
          credentialsId: 'github-credentials'
        )
      }
    }

    stage('Start Minikube Tunnel') {
      steps {
        script {
          if (!sh(script: "pgrep -f 'minikube tunnel'", returnStatus: true) == 0) {
            // Run minikube tunnel in background with sudo
            sh 'nohup sudo minikube tunnel > /dev/null 2>&1 &'
            sleep 10
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ${DOCKER_IMAGE} .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push ${DOCKER_IMAGE}
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          // Export KUBECONFIG env var for kubectl commands
          withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
            sh 'kubectl apply -f k8s/'
          }
        }
      }
    }

    stage('Wait for External IP') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
            timeout(time: 3, unit: 'MINUTES') {
              waitUntil {
                def svcJson = sh(script: "kubectl get svc resume-service -o json", returnStdout: true).trim()
                def json = readJSON text: svcJson
                def ip = json.status.loadBalancer?.ingress?.getAt(0)?.ip
                if (ip) {
                  echo "External IP assigned: ${ip}"
                  // Save IP for next stage (stash in env var)
                  env.EXTERNAL_IP = ip
                  return true
                } else {
                  echo "Waiting for external IP..."
                  sleep 10
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
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNS_EXIT_API_KEY')]) {
          script {
            def domain = "resumebuilder.publicvm.com"  // your domain here
            def ip = env.EXTERNAL_IP
            // Update DNSExit API with curl
            sh """
            curl -X POST "https://api.dnsexit.com/v2/dns/change" \\
              -H "Authorization: Bearer $DNS_EXIT_API_KEY" \\
              -H "Content-Type: application/json" \\
              -d '{
                "domain": "${domain}",
                "records": [
                  {
                    "type": "A",
                    "name": "@",
                    "data": "${ip}",
                    "ttl": 300
                  }
                ]
              }'
            """
            echo "DNS updated to IP: ${ip}"
          }
        }
      }
    }
  }

  post {
    success {
      echo 'Deployment pipeline completed successfully!'
    }
    failure {
      echo 'Deployment pipeline failed.'
    }
  }
}
