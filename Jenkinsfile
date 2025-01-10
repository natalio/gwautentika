
import groovy.json.JsonSlurperClassic

@NonCPS
def jsonParse(def json) {
    new groovy.json.JsonSlurperClassic().parseText(json)
}

def status_steps(def name, def status, def description) {
    try{

        def patchOrg = '''{ "iterationId": 1,
                            "state": "'''+status+'''",
                            "description": "'''+description+'''",
                            "context": {
                              "name": "'''+name+'''",
                              "genre": "ci-service"
                            },
                            "targetUrl": "'''+env.BUILD_URL+'''"
                          }'''
        echo patchOrg
        def statuses = httpRequest authentication: 'jenkins_git_azure_devops_access',
                               acceptType: 'APPLICATION_JSON',
                               contentType: 'APPLICATION_JSON',
                               httpMode: 'POST',
                               consoleLogResponseBody: true,
                               requestBody: patchOrg,
                               url: '''https://dev.azure.com/'''+env.ORG_NAME+'''/'''+env.PROJECT_NAME+'''/_apis/git/repositories/'''+env.REPOSITORY_NAME+'''/pullrequests/'''+env.PULL_REQUEST_ID+'''/statuses?api-version=7.1'''
        statuses.close()
    }catch(e){
    }
}

// Groovy Function to encode input String to Base64 String
def base64Encode(inputString){
    encoded = inputString.bytes.encodeBase64().toString()
    return encoded
}

// Groovy Function to decode Base64 input to String
def base64Decode(encodedString){
    byte[] decoded = encodedString.decodeBase64()
    String decode = new String(decoded)
    return decode
}

def format(encodedString){
    return encodedString.replace('.git', '')
}

def environments = ""
def existPullResquest=0
def is_release = 0
def git_username_password = 'jenkins-github-natalio-account'

pipeline {
    agent any
    environment {
        COMPOSITE_APPLICATION_PATH = "${env.WORKSPACE}"
        SERVER_CREDS = credentials('server2')
        AZ_CREDENTIALS_ID = 'jenkins_git_azure_devops_access'
    }
    stages {
        stage ("Configurando ambiente") {
            when{
                anyOf {
                    branch 'feature/*';
                    branch 'dev';
                    branch 'release/*';
                }
            }
            steps {
                script{
                    echo 'BRANCH_NAME...' + env.BRANCH_NAME
                    env.BRANCH_REF_NAME = 'refs/heads/' + env.BRANCH_NAME
                    /*def git_url = env.GIT_URL
                    def part_name_url = git_url.split('/')
                    env.ORG_NAME = part_name_url[3]
                    env.PROJECT_NAME = part_name_url[4]
                    env.REPOSITORY_NAME = part_name_url[6]*/

                    def config = readYaml file: env.WORKSPACE + '/config.yml'
                    env.IMAGE_REF_NAME =  config.project_sigla
                    env.PORT = config.project_port

                    env.BRANCH_REF_TARGET_NAME = 'refs/heads/dev'
                    env.BRANCH_TARGET_NAME = 'dev'

                    def branch_env_name = env.BRANCH_NAME
                    def project_env = []

                    if(branch_env_name == 'dev'){
                        def tag = VersionNumber(versionNumberString :'${BUILD_MONTH}.${BUILDS_TODAY}.${BUILD_NUMBER}',
                                                        versionPrefix : 'v1.'
                        )
                        env.BRANCH_TARGET_NAME = tag
                        env.BRANCH_REF_TARGET_NAME = 'refs/heads/release/'+env.BRANCH_TARGET_NAME
                        project_env = config.project_env.dev
                        withCredentials([string(credentialsId: "DEV_SERVER_HOST", variable: 'value')]) {
                            env.SERVER_HOST = value
                        }
                    }

                    if((branch_env_name).startsWith('release')){
                        env.BRANCH_TARGET_NAME = 'main'
                        env.BRANCH_REF_TARGET_NAME = 'refs/heads/main'
                        project_env = config.project_env.qual
                        withCredentials([string(credentialsId: "QUAL_SERVER_HOST", variable: 'value')]) {
                            env.SERVER_HOST = value
                        }
                    }

                    if(branch_env_name == 'main'){
                        project_env = config.project_env.prod
                        withCredentials([string(credentialsId: "PROD_SERVER_HOST", variable: 'value')]) {
                            env.SERVER_HOST = value
                        }
                    }

                    project_env.each { key, value ->
                        echo "environment key $key and value $value"
                        withCredentials([string(credentialsId: value, variable: 'value_original')]) {
                            environments = environments + "$key=$value_original\n"
                        }
                    }

                    writeFile file: '.env', text: environments

                }
            }
        }
    	stage ('Validação') {
    	    when{
                anyOf {
                    branch 'feature/*';
                    branch 'dev';
                    branch 'release/*';
                }
            }
            parallel {
                stage ("Verificando pullRequest...") {
                    steps {
                        script{
                            echo 'Verificando se existe pullRequest criado...'
                            def searchCriteria = '''/pullrequests?api-version=7.1&searchCriteria.sourceRefName='''+env.BRANCH_REF_NAME

                            if(env.BRANCH_NAME != 'dev'){
                                searchCriteria+'''&searchCriteria.targetRefName='''+env.BRANCH_REF_TARGET_NAME
                            }
                            /*def response = httpRequest authentication: 'jenkins_git_azure_devops_access',
                                                     acceptType: 'APPLICATION_JSON',
                                                     validResponseCodes: '200',
                                                     httpMode: 'GET',
                                                     url: '''https://dev.azure.com/'''+env.ORG_NAME+'''/'''+env.PROJECT_NAME+'''/_apis/git/repositories/'''+env.REPOSITORY_NAME+searchCriteria
                            println("Status: ${response.status}")
                            println("Response: ${response.content}")
                            println("Headers: ${response.headers}")
                            def pullRequest = jsonParse(response.content)
                            response.close()
                            if(pullRequest.count>0){
                                echo 'pullRequest criado'
                                for (ii = 0; ii < pullRequest.count; ii++){
                                    def match_release = (pullRequest.value[ii].targetRefName =~ /release\//)

                                    is_release = match_release.size();

                                    if( env.BRANCH_REF_TARGET_NAME == pullRequest.value[ii].targetRefName || is_release > 0){
                                        env.PULL_REQUEST_ID = pullRequest.value[ii].pullRequestId
                                        existPullResquest = 1
                                    }
                                }
                            }else{
                                echo 'pullRequest nao criado'
                                existPullResquest = 0
                            }*/
                        }
                    }
                }
            }
        }

        stage ('DEV/HOMOL') {
            when{
                anyOf {
                    branch 'release/*';
                    branch 'dev';
                }
            }
            stages {
                stage ('Implantando') {
                    when{
                        anyOf {
                            branch 'dev';
                            //branch 'release/*';
                        }
                    }
                    steps{
                        script{

                           // Construir a imagem Docker
                           customImage = docker.build("uniteltmais/${env.IMAGE_REF_NAME}")

                           // Parar e remover o contêiner existente, se necessário
                           try {
                               sh "docker stop ${env.IMAGE_REF_NAME} || true"
                               sh "docker rm ${env.IMAGE_REF_NAME} || true"
                           } catch (e) {
                               echo "Não foi possível parar/remover o contêiner existente: ${e}"
                           }

                           // Rodar a nova imagem
                           sh """
                                docker run --name ${env.IMAGE_REF_NAME} \\
                                --env-file ./.env \\
                                -p ${env.PORT} \\
                                -d uniteltmais/${env.IMAGE_REF_NAME}:latest
                              """
                        }
                    }
                }
            }
        }

        stage ('PROD') {
            when{
                anyOf {
                    branch 'release/*';
                }
            }
            stages {
                stage ('Iniciando produção') {
                    agent { node { label 'prod' } }
                    stages {
                        stage ("Configurando ambiente") {
                            steps {
                                script{
                                    def config = readYaml file: env.WORKSPACE + '/config.yml'
                                    env.IMAGE_REF_NAME =  config.project_sigla
                                    env.PORT = config.project_port

                                    def project_env = []

                                    project_env = config.project_env.prod
                                    withCredentials([string(credentialsId: "PROD_SERVER_HOST", variable: 'value')]) {
                                        env.SERVER_HOST = value
                                    }

                                    project_env.each { key, value ->
                                        echo "environment key $key and value $value"
                                        withCredentials([string(credentialsId: value, variable: 'value_original')]) {
                                            environments = environments + "$key=$value_original\n"
                                        }
                                    }

                                    writeFile file: '.env', text: environments

                                }
                            }
                        }
                        stage ("Implantando") {
                            steps{
                                script{

                                   // Construir a imagem Docker
                                   customImage = docker.build("uniteltmais/${env.IMAGE_REF_NAME}")

                                   // Parar e remover o contêiner existente, se necessário
                                   try {
                                       sh "docker stop ${env.IMAGE_REF_NAME} || true"
                                       sh "docker rm ${env.IMAGE_REF_NAME} || true"
                                   } catch (e) {
                                       echo "Não foi possível parar/remover o contêiner existente: ${e}"
                                   }

                                   // Rodar a nova imagem
                                   sh """
                                        docker run --name ${env.IMAGE_REF_NAME} \\
                                        --env-file ./.env \\
                                        -p ${env.PORT} \\
                                        -d uniteltmais/${env.IMAGE_REF_NAME}:latest
                                      """
                                }
                            }
                        }
                    }

                }
            }
        }

        stage ('Gerar release') {
            when{
               branch "dev"
            }
            steps{
                script{
                    if(existPullResquest == 0){
                        withCredentials([gitUsernamePassword(credentialsId: git_username_password,
                                         gitToolName: 'git-tool')]) {
                          sh "git branch release/${env.BRANCH_TARGET_NAME}"
                          sh "git push origin release/${env.BRANCH_TARGET_NAME}"
                        }
                    }
                }
            }
        }

        stage ('Pull Request') {
            when{
                anyOf {
                    branch 'feature/*';
                    branch 'dev';
                    branch 'release/*';
                }
            }
            steps{
                script{
                    echo '''Criando pull request '''+env.BRANCH_NAME+''' para '''+env.BRANCH_TARGET_NAME

                    if(existPullResquest == 0){
                         def patchOrg = '''{
                             "sourceRefName": "'''+env.BRANCH_REF_NAME+'''",
                             "targetRefName": "'''+env.BRANCH_REF_TARGET_NAME+'''",
                             "title": "'''+env.BRANCH_NAME+''' -> '''+env.BRANCH_TARGET_NAME+'''",
                             "description": "Adicionando '''+env.BRANCH_NAME+''' para '''+env.BRANCH_TARGET_NAME+'''",
                             "completionOptions":{
                                     "deleteSourceBranch": false,
                                     "bypassPolicy": false,
                                     "mergeStrategy": "noFastForward",
                                     "triggeredByAutoComplete":false
                             }
                         }'''
                         echo patchOrg

                        def uri = '''https://dev.azure.com/'''+env.ORG_NAME+'''/'''+env.PROJECT_NAME+'''/_apis/git/repositories/'''+env.REPOSITORY_NAME+'''/pullrequests?api-version=7.1'''

                        echo uri
                        /*
                        def cratePR = httpRequest authentication: 'jenkins_git_azure_devops_access',
                                                   acceptType: 'APPLICATION_JSON',
                                                   contentType: 'APPLICATION_JSON',
                                                   httpMode: 'POST',
                                                   consoleLogResponseBody: true,
                                                   requestBody: patchOrg,
                                                   validResponseCodes: '201,409',
                                                   url: uri
                        def pullRequest = jsonParse(cratePR.content)
                        env.PULL_REQUEST_ID = pullRequest.pullRequestId
                        cratePR.close()*/
                        //status_steps('test','pending', 'Esperando Implantação...')
                    }
                }
            }
        }
    }

    post {
        cleanup {
            cleanWs()
        }
        success {
            echo 'Conclido com success'
        }
        failure{
            echo 'Conclido com falha'
        }
    }

}