# Otus devops course [Microservices]

## HW-16 Gitlab-ci-1
![Build Status](https://api.travis-ci.com/Otus-DevOps-2018-09/revard_microservices.svg?branch=gitlab-ci-1)

### Gitlab-ci

Manuals: 

https://about.gitlab.com/install/

https://packages.gitlab.com/gitlab/gitlab-ce/install

https://docs.gitlab.com/omnibus/README.html

https://docs.gitlab.com/omnibus/docker/README.html

#### Prepare infrastructure

In directory `/infra` you need to use terraform and ansible to prepare gitlab-ci host. Image created by packer.

Terraform: 
```
terraform applly/destroy
```

Ansible: 
```
ansible-playbook playbooks/gitlab-ci.yml
```

We use docker-compose to run gitlab in docker container by /srv/gitlab/docker-compose.yml

Wait a few minutes and check `http://<your-vm-ip>`

You need to register then. Feel free to create new groups and projects.

For adding new gitlab remote to your project:
```
> git remote add gitlab http://<your-gitlab>/<you_group>/<your_project_name>.git
> git push gitlab <you_branch>
```

#### Troubleshooting

In case if IP of gitlab changes and jobs failes trying clone repository from old IP you need to setup new config:
```
root@gitlab:/# vi /etc/gitlab/gitlab.rb 
EDIT --->  external_url 'http://<your_new_gitlab_IP>'
root@gitlab:/# gitlab-ctl reconfigure
root@gitlab:/# gitlab-ctl restart
```

### Runner

#### Manual setup

Runner in container and manual registration:  
```
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```

Register runner:
```
root@gitlab-ci:~# docker exec -it gitlab-runner gitlab-runner register
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://<YOUR-VM-IP>/
Please enter the gitlab-ci token for this runner:
<TOKEN>
Please enter the gitlab-ci description for this runner:
[38689f5588fe]: my-runner
Please enter the gitlab-ci tags for this runner (comma separated):
linux,xenial,ubuntu,docker
Whether to run untagged builds [true/false]:
[false]: true
Whether to lock the Runner to current project [true/false]:
[true]: false
Please enter the executor:
docker
Please enter the default Docker image (e.g. ruby:2.1):
alpine:latest
Runner registered successfully.
```

#### Half-manual setup

For half-manual registration of docker runner:
```
appuser@gitlab-runner:~$ sudo gitlab-runner register --name my-runner --url http://<gitlab_IP>/ /
--registration-token <gitlab_token>  --executor=docker --docker-image=ruby-2.4 /
--tag-list=linux --non-interactive
Runtime platform                                    arch=amd64 os=linux pid=16733 revision=7f00c780 version=11.5.1
Running in system-mode.                            
                                                   
Registering runner... succeeded                     runner=A4NCtKZ5
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded! 
```

#### Auto setup

Create gce based runner and autoregister by ansible in your gitlab-ce instance. 

In this scenario we use external role solval.gitlab_runner, so you need install it first.
For proper config edit tag_gitlab-runner.yml in ansible/group_vars dir, write you gitlab token. You can pun more than one runner in config.  

Create gce instances (using tags for define runner):
```
gcloud compute instances create gitlab-runner --tags=gitlab-runner  --image-family docker-host
```

For automation this you can write new conf in terraform.

For final runner  registration run playbook: 
```
ansible-playbook playbooks/gitlab-runner.yml
```

If you got some repo errors it reccomended to wait a few minutes for gitlab-runner instances get ready.

And finaly you will have new runner in gitlab-ce.

### Runners autoscale configuration

There is nice feature https://docs.gitlab.com/runner/configuration/autoscale.html

You can check my config for gce in file gitlab-runner.yml Unfortunately it not finished yet for proper running.

### Gitlab and Slack 

Manual https://docs.gitlab.com/ee/user/project/integrations/slack.html

Setup in gitlab website Project Settings > Integrations > Slack notifications

It looks like here for example - my [slack chanel.](https://devops-team-otus.slack.com/messages/CD9T2PKLZ/details/)


## HW-15 Docker-4
![Build Status](https://api.travis-ci.com/Otus-DevOps-2018-09/revard_microservices.svg?branch=docker-4)

### Play Docker networks

#### None network driver

Run `docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig`

#### Host network driver

Run `docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig`

#### Docker networks

Run 
```
sudo ln -s /var/run/docker/netns /var/run/netns 
sudo ip netns
```

#### Bridge network driver

Be careful this changes IPTABLES!

One net
```
docker network create reddit --driver bridge
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post <your-dockerhub-login>/post:1.0
docker run -d --network=reddit --network-alias=comment  <your-dockerhub-login>/comment:1.0
docker run -d --network=reddit -p 9292:9292 <your-dockerhub-login>/ui:1.0
```
Two nets
```
> docker network create back_net --subnet=10.0.2.0/24
> docker network create front_net --subnet=10.0.1.0/24

> docker run -d --network=front_net -p 9292:9292 --name ui <your-login>/ui:1.0
> docker run -d --network=back_net --name comment <your-login>/comment:1.0
> docker run -d --network=back_net --name post <your-login>/post:1.0
> docker run -d --network=back_net --name mongo_db \
 --network-alias=post_db --network-alias=comment_db mongo:latest 

> docker network connect front_net post
> docker network connect front_net comment 

> sudo iptables -nL -t nat

> ifconfig | grep br 

> brctl show <interface>
 bridge           name bridge id     STP enabled  interfaces
 br-4ac81d1bf266 8000.0242ae9beade    no          vethaf41855
                                                  vethe115d8d 

> ps ax | grep docker-proxy
```

### Docker compose

#### Install and setup

Install https://docs.docker.com/compose/install/#install-compose

Set your login `export USERNAME=<your-login>`

Set prefix of compose resources names `export COMPOSE_PROJECT_NAME=revard`

Main file `docker-compose.yml` 

```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      back_net:
        aliases:
         - comment_db
  ui:
    build: ./ui
    image: ${USERNAME}/ui:${UI-VERSION}
    ports:
      - ${PORT_HOST}:${PORT_CONTAINER}/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${POST-VERSION}
    networks:
      - back_net
      - front_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:${COMMENT-VERSION}
    networks:
      - back_net
      - front_net

volumes:
  post_db:

networks:
  front_net:
    driver: bridge
    ipam:
      driver: default
      config:
      -
        subnet: 10.0.1.0/24 
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
      -
        subnet: 10.0.2.0/24
```

File for override config `docker-compose.override.yml`
```
version: '3.3'
services:
  ui:
    volumes:
      - ./ui:/app
    command: "puma --debug -w 2"
  comment:
    volumes:
      - ./comment:/app
    command: "puma --debug -w 2"
  post:
    volumes:
      - ./post-py:/app
```

File with variables `.env`
```
USERNAME=user_name
PORT=9292
UI-VERSION=1.0
POST-VERSION=1.0
COMMENT-VERSION=1.0
MONGO-VERSION=3.2
```

#### Administration

Run or rebuid
```
$>  docker-compose up -d
revard_post_db_1_4a8d1cd179ec is up-to-date
revard_ui_1_12a17147876b is up-to-date
revard_post_1_4089dcc7897c is up-to-date
Starting revard_comment_1_38c8ec61e032 ... done
```
Status
```
$>  docker-compose ps
            Name                          Command             State            Ports
---------------------------------------------------------------------------------------------
revard_comment_1_38c8ec61e032   puma --debug -w 2             Exit 1
revard_post_1_4089dcc7897c      python3 post_app.py           Up
revard_post_db_1_4a8d1cd179ec   docker-entrypoint.sh mongod   Up       27017/tcp
revard_ui_1_12a17147876b        puma --debug -w 2             Up       0.0.0.0:9292->9292/tcp
```

Build single image 
```
$> docker-compose build ui
Building ui
Step 1/12 : FROM ruby:2.4-alpine3.8
 ---> bbbc1f86302c
...
 ---> Using cache
 ---> 7f177613dc1e

Successfully built 7f177613dc1e
Successfully tagged revard/ui:VERSION
```

Kill
```
$> docker-compose kill
Killing revard_ui_1_12a17147876b      ... done
Killing revard_post_1_4089dcc7897c    ... done
Killing revard_post_db_1_4a8d1cd179ec ... done
```
### Remake application for testing purpose

For remake application without rebuild container image we use volumes in docker-compose.override.yml 

Before run `docker-compose up -d` we need to write changes in source files.

In case of using docker-machine do nex steps. Copy this files to docker-host machine by `docker-machine scp -r . docker-host:` In docker-host don't forget to copy src from `/home/docker-user/` to your user home directory with project path, for example - `/home/your_user/user_microservices/src`.


## HW-14 Docker-3
![Build Status](https://api.travis-ci.com/Otus-DevOps-2018-09/revard_microservices.svg?branch=docker-3)

### Docker machine

#### Manual deploy app

```
 $ > docker-machine create --google-project docker-223411 --driver google  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host
$ > eval $(docker-machine env docker-host)

$ > docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.233.xx.xx:2376           v18.09.0

$ > docker build -t dockerhub_user/post:1.0 ./post-py
$ > docker build -t dockerhub_user/comment:1.0 ./comment
$ > docker build -t dockerhub_user/ui:1.0 ./ui

$ > docker network create reddit

$ > docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
$ > docker run -d --network=reddit --network-alias=post revard/post:1.0
$ > docker run -d --network=reddit --network-alias=comment revard/comment:1.0
$ > docker run -d --network=reddit -p 9292:9292 revard/ui:1.0

$ > docker ps -a
CONTAINER ID        IMAGE                COMMAND                  CREATED             STATUS              PORTS                    NAMES
3807b8e8be5e        revard/ui:1.0        "puma"                   40 minutes ago      Up 40 minutes       0.0.0.0:9292->9292/tcp   agitated_lehmann
351276696b34        revard/comment:1.0   "puma"                   41 minutes ago      Up 41 minutes                                boring_albattani
3777289a5c5b        revard/post:1.0      "python3 post_app.py"    43 minutes ago      Up 12 minutes                                adoring_tesla
0be9429ba655        mongo:latest         "docker-entrypoint.s…"   About an hour ago   Up 12 minutes       27017/tcp                silly_euclid

```

Try run with different network aliases

```
$ > docker run -d --network=reddit --network-alias=post_db1 --network-alias=comment_db1 mongo:latest
09a2be6955d534cfb9431b82ffc554a26c75aab0e213692b79ef50acc82f35c7
$ > docker run -d --network=reddit -e "POST_DATABASE_HOST=post_db1" --network-alias=post1 revard/post:1.0
f04e331b2086ee6fd850713a99668299601406a8dc406f53e49c75d66ace83cf
$ >  docker run -d --network=reddit -e "COMMENT_DATABASE_HOST=comment_db1" --network-alias=comment1 revard/comment:1.0
8b0236fb666ce7fc9dde66e196c4aff0fd42d0c7dc18a6e3942c65c20b79af96
$ > docker run -d --network=reddit -e "POST_SERVICE_HOST=post1" -e "COMMENT_SERVICE_HOST=comment1" -p 9292:9292 revard/ui:1.0
2b44c52a39549b0bb03264f6dadc004e26c62df4ec1c2df1842da11cf809d0af
 $ > docker ps -a
CONTAINER ID        IMAGE                COMMAND                  CREATED              STATUS                        PORTS                    NAMES
2b44c52a3954        revard/ui:1.0        "puma"                   About a minute ago   Up About a minute             0.0.0.0:9292->9292/tcp   kind_tharp
8b0236fb666c        revard/comment:1.0   "puma"                   2 minutes ago        Up 2 minutes                                           amazing_shtern
f04e331b2086        revard/post:1.0      "python3 post_app.py"    2 minutes ago        Up 2 minutes                                           wizardly_meninsky
09a2be6955d5        mongo:latest         "docker-entrypoint.s…"   4 minutes ago        Up 4 minutes                  27017/tcp                eager_bell
3807b8e8be5e        revard/ui:1.0        "puma"                   About an hour ago    Exited (137) 32 minutes ago                            agitated_lehmann
351276696b34        revard/comment:1.0   "puma"                   About an hour ago    Exited (137) 32 minutes ago                            boring_albattani
3777289a5c5b        revard/post:1.0      "python3 post_app.py"    About an hour ago    Exited (137) 32 minutes ago                            adoring_tesla
0be9429ba655        mongo:latest         "docker-entrypoint.s…"   2 hours ago          Exited (137) 27 minutes ago                            silly_euclid
```

#### Docker volume

```
$ > docker volume create reddit_db
reddit_db

$ > docker run -d --network=reddit --network-alias=post_db \
--network-alias=comment_db -v reddit_db:/data/db mongo:latest
```

## HW-13 Docker-2
![Build Status](https://api.travis-ci.com/Otus-DevOps-2018-09/revard_microservices.svg?branch=docker-2)

### Docker machine

#### Install

For Linux https://docs.docker.com/machine/install-machine/

Don`t forget to setup gcloud for docker machine authentication in cloud.
```
$ gcloud init
You must log in to continue. Would you like to log in (Y/n)? Y
Your browser has been opened to visit:
 https://accounts.google.com/o/oauth2/.... 

$ gcloud auth application-default login
Your browser has been opened to visit:
 https://accounts.google.com/o/oauth2/....
```

#### Create machine

```
~$ docker-machine create --driver google  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host
...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env docker-host
```

#### Admin machines

Status
```
~$ docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                         SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://35.241.210.113:2376           v18.09.0
```

Setup for using concrete machine run `$ eval $(docker-machine env docker-host)`

Run container
```
~$ docker run --rm --pid host -ti tehbilly/htop
~$ docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                         SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.241.210.113:2376           v18.09.0
```

Build image
```
~/_microservices/docker-monolith$ docker build -t reddit:latest .
Sending build context to Docker daemon  8.704kB
Step 1/11 : FROM ubuntu:16.04
16.04: Pulling from library/ubuntu
...
Successfully built 3ed743eef79f
Successfully tagged reddit:latest
```

See image
```
~/_microservices/docker-monolith$ docker images -a
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
reddit              latest              3ed743eef79f        33 seconds ago       676MB
<none>              <none>              4f35292dbc9e        33 seconds ago       676MB
<none>              <none>              46ca2ffb1197        35 seconds ago       676MB
<none>              <none>              5cd5b36530c4        49 seconds ago       638MB
<none>              <none>              214b37c20102        49 seconds ago       638MB
<none>              <none>              528295031f56        49 seconds ago       638MB
<none>              <none>              1e806f4d7d3a        49 seconds ago       638MB
<none>              <none>              dc42c631b5c2        51 seconds ago       637MB
<none>              <none>              dfd9cf4c3eda        About a minute ago   634MB
<none>              <none>              7199470322d5        About a minute ago   141MB
ubuntu              16.04               a51debf7e1eb        3 days ago           116MB
hello-world         latest              4ab4c602aa5e        2 months ago         1.84kB
tehbilly/htop       latest              4acd2b4de755        7 months ago         6.91MB
```

Run container
```
~/_microservices/docker-monolith$  docker run --name reddit -d --network=host reddit:latest
38284a02d8a381e9b4649ecb51c162b7111d9709872743a299b91f898cf719a6
appuser@otus-hw:~/revard_microservices/docker-monolith$ docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                         SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.241.210.113:2376           v18.09.0
```

### Docker hub

Register account on https://hub.docker.com/

Login
```
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: revard
Password:
WARNING! Your password will be stored unencrypted in /home/appuser/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
Push image on docker hub
```
~/_microservices/docker-monolith$ docker tag reddit:latest user_name/otus-reddit:1.0
~/_microservices/docker-monolith$ docker push user_name/otus-reddit:1.0
The push refers to repository [docker.io/user_name/otus-reddit]
508e32e2dae9: Pushed
388aaa0ac164: Pushed
b35eb69f9227: Pushed
ca70d14be66b: Pushed
af3fbf0d7123: Pushed
6163aebf7183: Pushed
a1395fab23f7: Pushed
a7aefc6d8f2c: Pushed
1cc2b87eac1f: Pushed
3db5746c911a: Mounted from library/ubuntu
819a824caf70: Mounted from library/ubuntu
647265b9d8bc: Mounted from library/ubuntu
41c002c8a6fd: Mounted from library/ubuntu
1.0: digest: sha256:e2c876391a933d56ba60fc23d7afce82d4497bd84a2bc59859b1034bd2772d6f size: 3034
~/_microservices/docker-monolith$
```

Try run image
```
$ > sudo  docker run --name reddit -d -p 9292:9292 user_name/otus-reddit:1.0
Unable to find image 'user_name/otus-reddit:1.0' locally
1.0: Pulling from user_name/otus-reddit
7b8b6451c85f: Pull complete
ab4d1096d9ba: Pull complete
e6797d1788ac: Pull complete
e25c5c290bde: Pull complete
d479fd78a586: Pull complete
4121177ab275: Pull complete
e7eeac0b7904: Pull complete
e0707aa30dad: Pull complete
f75dd46b807b: Pull complete
7c0533537df5: Pull complete
b648933eee5d: Pull complete
229df837abd4: Pull complete
a7ad62556449: Pull complete
Digest: sha256:e2c876391a933d56ba60fc23d7afce82d4497bd84a2bc59859b1034bd2772d6f
Status: Downloaded newer image for user_name/otus-reddit:1.0
f8793580e2b7329fbbc3e78687663c7f3a165a1178412ef94bd4983a405837a0
```

For automated deployment of infrastructure see tree bellow:
```
$ > tree infra/
infra/
├── ansible
│   ├── ansible.cfg  - Main ansible config file
│   ├── environments
│   │   ├── prod
│   │   │   └──... 
│   │   └── stage
│   │       ├── gce.ini  - GCP Settings
│   │       ├── gce.py   - Inventory script 
│   │       └──... 
│   ├── playbooks
│   │   ├── docker-server.yml  - Playbook to create docker host 
│   │   ├── packer-docker.yml  - Playbook to create docker host for packer
│   │   ├── reddit-container-delete.yml  - Playbook to delete container
│   │   ├── reddit-container.yml  - Playbook to create  and deploy container
│   │   └── site.yml
│   ├── requirements.txt  - Requirements for ansible galaxy roles
│   ├── requirements.yml
│   ├── roles
│   │   ├── geerlingguy.docker
│   │   │   └── ...
│   │   └── geerlingguy.pip
│   │       └── ...
│   ├── secrets.yml   - Crypted login info for dockerhub
│   ├── templates
│   └── vars.yml
├── packer
│   ├── scripts
│   │   └── install_docker.sh
│   ├── ubuntu16_docker-ansible.json  - Packer file with ansible palybook
│   ├── ubuntu16_docker.json  - Packer file with clasic scrips
│   ├── variables.json
│   └── variables.json.example
└── terraform
    ├── modules
    │   └── docker-host
    │       ├── main.tf  - Main config file for module
    │       ├── outputs.tf  - Output config to show IP
    │       └── variables.tf
    ├── prod
    ├── stage
    │   ├── main.tf  - Main config file uses module
    │   ├── output.tf  - Output config to show IP
    │   ├── terraform.tfstate
    │   ├── terraform.tfvars
    │   └── variables.tf
    ├── storage-bucket.tf  - For gcp bucket
    ├── terraform.tfvars
    └── variables.tf
```


## HW-12 Docker-1
![Build Status](https://api.travis-ci.com/Otus-DevOps-2018-09/revard_microservices.svg?branch=docker-1)

### Docker

#### Install

Manual https://docs.docker.com/install/linux/docker-ce/ubuntu/

#### Playing docker

Run container.
```
$ > sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
d1725b59e92d: Pull complete
Digest: sha256:0add3ace90ecb4adbf7777e9aacf18357296e799f81cabc9fde470971e499788
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

See running containers.
```
$ > sudo docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
9bb5e91b1730        ubuntu:16.04        "/bin/bash"         3 minutes ago       Up About a minute                       sharp_poitras
```

See all containers.
```
$ > sudo docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                      PORTS               NAMES
7d99dad5bd1f        ubuntu:16.04        "/bin/bash"         12 seconds ago      Exited (1) 2 seconds ago                        inspiring_wozniak
9bb5e91b1730        ubuntu:16.04        "/bin/bash"         36 seconds ago      Exited (0) 21 seconds ago                       sharp_poitras
d0e96d2eca37        hello-world         "/hello"            3 minutes ago       Exited (0) 3 minutes ago                        adoring_hopper
b0bc40afc6ed        hello-world         "/hello"            4 minutes ago       Exited (0) 4 minutes ago                        heuristic_burnell
```

Docker images.
```
$ > sudo  docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
tgz/ubuntu-tmp-file   latest              7a57124b7d2b        8 seconds ago       116MB
ubuntu                16.04               a51debf7e1eb        15 hours ago        116MB
nginx                 latest              e81eb098537d        3 days ago          109MB
hello-world           latest              4ab4c602aa5e        2 months ago        1.84kB
```

Exec commnad in container.
```
$ > sudo docker exec -it e9b869ee49ca bash
root@e9b869ee49ca:/# ps axf
  PID TTY      STAT   TIME COMMAND
   11 pts/1    Ss     0:00 bash
   21 pts/1    R+     0:00  \_ ps axf
    1 pts/0    Ss+    0:00 bash
root@e9b869ee49ca:/# exit
```

Create image.
```
$ > sudo  docker commit e9b869ee49ca tgz/ubuntu-tmp-file
sha256:7a57124b7d2b2499fea1577eb20763de7f78a9ec6bc4de07937bd641302066c4
```

Inspect image or container.
```
$ > sudo docker inspect e9b869ee49ca
[
    {
        "Id": "e9b869ee49ca26c905f8d975884347470c0d0004c3de244ecdaafda91c372704",
        "Created": "2018-11-20T12:25:22.297767276Z",
        "Path": "bash",
...
```
Docker df.
```
$ > sudo  docker system df
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              5                   3                   225.5MB             116.4MB (51%)
Containers          6                   0                   63B                 63B (100%)
Local Volumes       0                   0                   0B                  0B
Build Cache         0                   0                   0B                  0B

```

Kill containers and delete images.
```
 $ > sudo  docker kill $(sudo docker ps -q)
2b84b8ad80bf
e9b869ee49ca
9bb5e91b1730
$ > sudo  docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

$ > sudo docker rm $(sudo docker ps -a -q)
2b84b8ad80bf
e9b869ee49ca
7d99dad5bd1f
9bb5e91b1730
d0e96d2eca37
b0bc40afc6ed

$ > sudo docker rmi $(sudo docker images -q)
Untagged: tgz/ubuntu-tmp-file:latest
Deleted: sha256:63e0c42e14e30939995c315d2bda50b05f8b2fb5fef6a260260bb489d5bf8cd3
Deleted: sha256:3f087d611835b44af0d4c936759aa3809a552f675b12cbfd3b51bc118804d0d8
Deleted: sha256:7a57124b7d2b2499fea1577eb20763de7f78a9ec6bc4de07937bd641302066c4
Deleted: sha256:15ac0ab4e42ab4453bfa1b411c3d103409b51a2500924aa5bb5b9e91aac8358b
Untagged: ubuntu:16.04
...
```


