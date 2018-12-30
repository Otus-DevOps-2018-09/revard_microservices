default: start-bundle

start-bundle: dm-create dc-up

stop-bundle: dc-stop dm-rm

build: build-comment build-post build-ui build-prometheus build-cloudprober build-alertmanager

push: push-comment push-post push-ui push-prometheus push-cloudprober push-alertmanager

build-comment:
	cd src/comment && bash docker_build.sh
build-post:
	cd src/post-py && bash docker_build.sh
build-ui:
	cd src/ui && bash docker-build.sh
build-prometheus:
	cd monitoring/prometheus && docker build -t ${USER_NAME}/prometheus .
build-cloudprober:
	cd monitoring/cloudprober && docker build -t ${USER_NAME}/cloudprober .
build-alertmanager:
	cd monitoring/alertmanager && docker build -t ${USER_NAME}/alertmanager .


push-comment:
	docker push ${USER_NAME}/comment
push-post:
	docker push ${USER_NAME}/post
push-ui:
	docker push ${USER_NAME}/ui
push-prometheus:
	docker push ${USER_NAME}/prometheus
push-cloudprober:
	docker push ${USER_NAME}/cloudprober
push-alertmanager:
	docker push ${USER_NAME}/alertmanager

dc-build: 
	cd docker/ && docker-compose build
	cd docker/ && docker-compose -f docker-compose-monitoring.yml build
dc-up: 
	cd docker/ && docker-compose up -d
	cd docker/ && docker-compose -f docker-compose-monitoring.yml up -d
dc-down: 
	cd docker/ && docker-compose down
	cd docker/ && docker-compose -f docker-compose-monitoring.yml down
dc-stop: 
	cd docker/ && docker-compose stop
	cd docker/ && docker-compose -f docker-compose-monitoring.yml stop
dc-start: 
	cd docker/ && docker-compose start
	cd docker/ && docker-compose -f docker-compose-monitoring.yml start

dm-create:
	docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
     docker-host \
	 && eval $(docker-machine env docker-host)

dm-rm:
	docker-machine rm docker-host && eval $(docker-machine env -u)