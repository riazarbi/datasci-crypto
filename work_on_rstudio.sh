#!/bin/bash


persistent=''
folder=datasci-crypto
IMAGE=riazarbi/datasci-crypto:latest

print_usage() {
  printf "Usage: \n Use the option -d to specify a folder. eg: work_on_rstudio -d test. \n To make the container persistent add a -p flag. eg: work_on_rstudio -pd test \n"
}

while getopts 'pd:' flag; do
  case "${flag}" in
    p) persistent='true' ;;
    d) folder="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

docker pull $IMAGE

if [ -n "$folder" ]; then
  if [ -z "$persistent" ]; then
    echo "Starting disposable container mounted on /home/$USER/projects/$folder"
    docker run -it --rm \
    --name=$folder \
    -v /home/$USER/projects/$folder:/home/jovyan/$folder \
    -v /home/$USER/projects/secrets.json:/home/jovyan/secrets.json: \
    -e NB_UID=$UID \
    -p 8888:8888 \
    --user root \
    -e CHOWN_HOME=yes \
    -e CHOWN_HOME_OPTS='-R' \
    -e GRANT_SUDO=yes \
    -e JUPYTER_ENABLE_LAB=yes \
    $IMAGE /bin/bash start-notebook.sh --NotebookApp.default_url="/rstudio" --no-browser --NotebookApp.token=""
  else
    echo "Starting persistent container mounted on /home/riaz/projects/$folder"
    docker run -it --restart=always \
    --name=$folder \
    -v /home/$USER/projects/$folder:/home/jovyan/$folder \
    -v /home/$USER/projects/secrets.json:/home/jovyan/secrets.json \
    -e NB_UID=$UID \
    -p 8888:8888 \
    --user root \
    -e CHOWN_HOME=yes \
    -e CHOWN_HOME_OPTS='-R' \
    -e GRANT_SUDO=yes \
    -e JUPYTER_ENABLE_LAB=yes \
    $IMAGE /bin/bash start-notebook.sh --NotebookApp.default_url="/rstudio" --no-browser --NotebookApp.token=""
  fi
else
    echo "You need to enter a directory"
    print_usage
fi
