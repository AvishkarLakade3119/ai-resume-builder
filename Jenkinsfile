pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        IMAGE_NAME = "avishkarlakade/resume-builder"
        IMAGE_TAG = "latest"
        KUBE_CONFIG = credentials('kubeconfig-cred') // Jenkins credential ID for kubeconfig
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials' // Jenkins credential ID for Docker Hub
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    docker.withRegistry("https://${env.REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        echo 'Logged in to Docker Hub'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
                }
            }
        }

        stage('Deploy to Kubernetes (NodePort)') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG

                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    '''
                }
            }
        }

        stage('Print NodePort & IP for DNS Mapping') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG')]) {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG

                        echo "🔗 External Access Info:"
                        NODE_PORT=$(kubectl get svc resume-builder-service -o jsonpath="{.spec.ports[0].nodePort}")
                        NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[?(@.type=='InternalIP')].address}")

                        echo "Access your app at: http://$NODE_IP:$NODE_PORT"
                        echo "✅ Now go to your DNS provider (e.g., GoDaddy/Cloudflare) and point your domain/subdomain A record to $NODE_IP"
                    '''
                }
            }
        }
    }
}
