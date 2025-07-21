pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "avilakade/ai-resume-builder"
        DOCKER_TAG = "latest"
        KUBE_CONFIG_CREDENTIAL_ID = 'kubeconfig-cred'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    }

    stages {
        stage('Clone Code') {
            steps {
                git credentialsId: 'github-credentials', url: 'https://github.com/AvishkarLakade3119/ai-resume-builder'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$DOCKER_TAG .'
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "$DOCKER_CREDENTIALS_ID", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $DOCKER_IMAGE:$DOCKER_TAG
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: "${KUBE_CONFIG_CREDENTIAL_ID}", variable: 'KUBECONFIG')]) {
                    sh '''
                    cat <<EOF | kubectl apply -f -
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      name: resume-app
                    spec:
                      replicas: 1
                      selector:
                        matchLabels:
                          app: resume
                      template:
                        metadata:
                          labels:
                            app: resume
                        spec:
                          containers:
                          - name: resume-container
                            image: $DOCKER_IMAGE:$DOCKER_TAG
                            ports:
                            - containerPort: 3000
                    EOF

                    cat <<EOF | kubectl apply -f -
                    apiVersion: v1
                    kind: Service
                    metadata:
                      name: resume-service
                    spec:
                      selector:
                        app: resume
                      ports:
                      - protocol: TCP
                        port: 80
                        targetPort: 3000
                        nodePort: 30080
                      type: NodePort
                    EOF
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}
