pipeline {
  agent any

  environment {
    KUBECONFIG = credentials('kubeconfig')       // Your kubeconfig.yaml Jenkins credential ID
    CF_API_TOKEN = credentials('cloudflare-token') // Cloudflare API Token (create a secret text credential)
    CF_ZONE_ID = 'your-cloudflare-zone-id'
    CF_RECORD_ID = 'your-cloudflare-record-id'
    DNS_NAME = 'resume.yourdomain.com'
    NODEPORT = '30080'
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/avilakade/ai-resume-builder.git'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ai-resume-builder .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker tag ai-resume-builder $DOCKER_USER/ai-resume-builder:latest
            docker push $DOCKER_USER/ai-resume-builder:latest
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
        cat <<EOF | kubectl apply -f -
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: ai-resume-builder
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: ai-resume-builder
          template:
            metadata:
              labels:
                app: ai-resume-builder
            spec:
              containers:
              - name: resume
                image: $DOCKER_USER/ai-resume-builder:latest
                ports:
                - containerPort: 3000
        ---
        apiVersion: v1
        kind: Service
        metadata:
          name: ai-resume-builder-service
        spec:
          type: NodePort
          selector:
            app: ai-resume-builder
          ports:
            - port: 80
              targetPort: 3000
              nodePort: ${NODEPORT}
        EOF
        '''
      }
    }

    stage('Get External IP') {
      steps {
        script {
          def externalIP = sh(script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"ExternalIP\")].address}'", returnStdout: true).trim()
          env.EXTERNAL_IP = externalIP
          echo "External IP: ${externalIP}"
        }
      }
    }

    stage('Update DNS via Cloudflare API') {
      steps {
        sh '''
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{
          "type": "A",
          "name": "'"$DNS_NAME"'",
          "content": "'"$EXTERNAL_IP"'",
          "ttl": 120,
          "proxied": false
        }'
        '''
      }
    }
  }
}
