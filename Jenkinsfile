pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'avishkarlakade3119/ai-resume-builder:latest'
        K8S_NAMESPACE = 'default'
        KUBECONFIG_FILE = credentials('kubeconfig')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        def customImage = docker.build("${DOCKER_IMAGE}")
                        customImage.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                    sh 'kubectl apply -f k8s/'
                }
            }
        }

        stage('Wait for External IP') {
            steps {
                script {
                    def externalIP = ""
                    timeout(time: 2, unit: 'MINUTES') {
                        waitUntil {
                            externalIP = sh(script: "kubectl get svc resume-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
                            return externalIP && externalIP != "null" && externalIP != ""
                        }
                    }
                    env.EXTERNAL_IP = externalIP
                    echo "External IP acquired: ${EXTERNAL_IP}"
                }
            }
        }

        stage('Update DNS via DNSExit API') {
            steps {
                withCredentials([string(credentialsId: 'dnsexit-api-key', variable: 'DNSEXIT_API_KEY')]) {
                    script {
                        sh """
                        curl -X POST "https://api.dnsexit.com/dnsUpdate/ipUpdate" \\
                            -d "apikey=${DNSEXIT_API_KEY}" \\
                            -d "hostname=resumebuilder.publicvm.com" \\
                            -d "ip=${EXTERNAL_IP}"
                        """
                        echo "DNS record updated to point resumebuilder.publicvm.com -> ${EXTERNAL_IP}"
                    }
                }
            }
        }
    }
}
