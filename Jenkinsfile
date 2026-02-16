pipeline {
  agent any

  environment {
    TF_DIR = "terraform"
    ANSIBLE_DIR = "ansible"
  }

  stages {
    stage("Checkout") {
      steps {
        checkout scm
      }
    }

    stage("Terraform Init") {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -e
            terraform init
          '''
        }
      }
    }

    stage("Terraform Apply") {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -e
            terraform apply -auto-approve
          '''
        }
      }
    }

    stage("Get App IP") {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -e
            terraform output -raw app_public_ip > ../app_ip.txt
            cat ../app_ip.txt
          '''
        }
      }
    }

    stage("Ansible Configure App") {
      steps {
        // IMPORTANT: You will add the SSH private key in Jenkins credentials, ID = ec2-ssh-key
        sshagent(credentials: ['ec2-ssh-key']) {
          dir("${ANSIBLE_DIR}") {
            sh '''
              set -e
              APP_IP=$(cat ../app_ip.txt)

              cat > inventory.ini <<EOF
[app]
${APP_IP} ansible_user=ubuntu
EOF

              export ANSIBLE_HOST_KEY_CHECKING=False
              ansible-playbook -i inventory.ini site.yml
            '''
          }
        }
      }
    }
  }
}
