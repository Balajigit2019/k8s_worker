
pipeline {
    agent any 
    stages {      
         stage('terraform init') { 
            steps {
               sh 'terraform init'
            }    
        }
        stage('terraform plan') { 
            steps {
               sh 'terraform plan'
            }    
        }
        stage('terraform apply') {
            steps {
                sh 'TF_LOG=DEBUG terraform apply --auto-approve'
            }
        }
        stage('Download') {
            steps {
                sh 'echo "artifact file" > generatedFile.txt'
            }
        }     
    }         
}    
/*
        stage('terraform destroy') { 
            steps {
               sh 'terraform destroy --auto-approve'
            }    
        }        
    }   
}   
*/
