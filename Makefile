default: start-bundle

start-bundle: dm-create dc-up
stop-bundle: dc-stop dm-rm

build: build-comment build-post build-ui build-prometheus build-cloudprober build-grafana build-alertmanager build-telegraf
push: push-comment push-post push-ui push-prometheus push-cloudprober push-grafana push-alertmanager push-telegraf

comment: build-comment push-comment
post: build-post push-post
ui: build-ui push-ui
prometheus: build-prometheus push-prometheus
cloudprober: build-cloudprober push-cloudprober
grafana: build-grafana push-grafana
alertmanager: build-alertmanager push-alertmanager
telegraf: build-telegraf push-telegraf

dc-build: dc-build-app  dc-build-mon
dc-up: dc-up-app dc-up-mon
dc-down: dc-down-app dc-down-mon
dc-stop: dc-stop-app dc-stop-mon
dc-start: dc-start-app  dc-start-mon

build-comment:
	cd src/comment && bash docker_build.sh
build-post:
	cd src/post-py && bash docker_build.sh
build-ui:
	cd src/ui && bash docker_build.sh
build-prometheus:
	cd monitoring/prometheus && docker build -t ${USER_NAME}/prometheus .
build-cloudprober:
	cd monitoring/cloudprober && docker build -t ${USER_NAME}/cloudprober .
build-grafana:
	cd monitoring/grafana && docker build -t ${USER_NAME}/grafana .
build-alertmanager:
	cd monitoring/alertmanager && docker build -t ${USER_NAME}/alertmanager .
build-telegraf:
	cd monitoring/telegraf && docker build -t ${USER_NAME}/telegraf .


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
push-grafana:
	docker push ${USER_NAME}/grafana
push-alertmanager:
	docker push ${USER_NAME}/alertmanager
push-telegraf:
	docker push ${USER_NAME}/telegraf

dc-build-app: 
	cd docker/ && docker-compose build
dc-build-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml build
dc-up-app: 
	cd docker/ && docker-compose up -d
dc-up-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml up -d
dc-down-app: 
	cd docker/ && docker-compose down
dc-down-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml down
dc-stop-app: 
	cd docker/ && docker-compose stop
dc-stop-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml stop
dc-start-app: 
	cd docker/ && docker-compose start
dc-start-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml start

dm-create:
	docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-address static-ip \
    --google-zone europe-west1-b \
    --google-preemptible \
     docker-host 
	echo 'Run - eval $$(docker-machine env docker-host)'

dm-rm:
	docker-machine rm docker-host
	echo 'Run - eval $$(docker-machine env -u)'