pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "avishkarlakade/ai-resume-builder"
        DOCKER_TAG = "latest"
        NODE_PORT = "30080"  // Must match the nodePort in your service.yaml
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder.git'
            }
        }

        stage('Start Minikube Tunnel') {
            steps {
                // You can skip this if you're not using tunnel for NodePort service
                script {
                    // Just ensure minikube is running
                    sh "minikube status || minikube start"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh "kubectl apply -f k8s/"
                }
            }
        }

        stage('Get Minikube IP') {
            steps {
                script {
                    // Get minikube IP and store it in env variable
                    def minikubeIp = sh(script: "minikube ip", returnStdout: true).trim()
                    echo "Minikube IP: ${minikubeIp}"
                    env.MINIKUBE_IP = minikubeIp
                }
            }
        }

        stage('Update DNS with DNSExit') {
            steps {
                withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNS_EXIT_API_KEY')]) {
                    script {
                        def fullDomain = "resumebuilder.publicvm.com"
                        def target = "${env.MINIKUBE_IP}:${env.NODE_PORT}"

                        echo "Updating DNS record for ${fullDomain} to point to ${target}"

                        // Example curl command to update DNSExit A record with IP (adjust as per DNSExit API)
                        sh """
                        curl -X POST "https://api.dnsexit.com/dns" \\
                          -H "Authorization: Bearer ${DNS_EXIT_API_KEY}" \\
                          -d '{
                                "domain": "${fullDomain}",
                                "type": "A",
                                "value": "${env.MINIKUBE_IP}"
                              }'
                        """
                    }
                }
            }
        }

        stage('Done') {
            steps {
                echo "Deployment complete! Access your app at http://${env.MINIKUBE_IP}:${env.NODE_PORT}"
            }
        }
    }
}
