pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "avishkarlakade/ai-resume-builder"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main',
            credentialsId: 'github-credentials',
            url: 'https://github.com/AvishkarLakade3119/ai-resume-builder.git'
      }
    }

    stage('Start Minikube Tunnel') {
      steps {
        script {
          // Kill any existing tunnel processes
          sh "pgrep -f minikube tunnel || true | xargs -r sudo kill -9 || true"
          // Start minikube tunnel in background
          sh "nohup sudo minikube tunnel &"
          sleep 10
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DOCKER_IMAGE .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push $DOCKER_IMAGE
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
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
            script {
              timeout(time: 3, unit: 'MINUTES') {
                waitUntil {
                  def svcJson = sh(script: "kubectl get svc resume-service -o json", returnStdout: true).trim()
                  def json = readJSON text: svcJson
                  def ip = json.status.loadBalancer?.ingress?.getAt(0)?.ip
                  if (ip) {
                    echo "External IP assigned: ${ip}"
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
    }

    stage('Update DNS with DNSExit') {
      steps {
        withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNS_EXIT_API_KEY')]) {
          script {
            def domain = 'resumebuilder.publicvm.com'
            def ip = env.EXTERNAL_IP
            echo "Updating DNS for ${domain} to IP ${ip}"

            // Replace the following curl command with your DNSExit API call
            sh """
              curl -X POST https://api.dnsexit.com/dns/update \
                -H "Authorization: Bearer ${DNS_EXIT_API_KEY}" \
                -d "domain=${domain}&ip=${ip}"
            """
          }
        }
      }
    }
  }
}
