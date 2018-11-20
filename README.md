# Otus devops course [Microservices]

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

Kill ontainersi and delete images.
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
└─ $ > sudo docker rmi $(sudo docker images -q)
Untagged: tgz/ubuntu-tmp-file:latest
Deleted: sha256:63e0c42e14e30939995c315d2bda50b05f8b2fb5fef6a260260bb489d5bf8cd3
Deleted: sha256:3f087d611835b44af0d4c936759aa3809a552f675b12cbfd3b51bc118804d0d8
Deleted: sha256:7a57124b7d2b2499fea1577eb20763de7f78a9ec6bc4de07937bd641302066c4
Deleted: sha256:15ac0ab4e42ab4453bfa1b411c3d103409b51a2500924aa5bb5b9e91aac8358b
Untagged: ubuntu:16.04
...
```


