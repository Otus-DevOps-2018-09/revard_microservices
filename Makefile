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
fluentd: build-fluentd push-fluentd

dc-build: dc-build-app dc-build-mon dc-build-log
dc-up:  dc-up-mon dc-up-log dc-up-app
dc-down: dc-down-mon dc-down-log dc-down-app
dc-stop: dc-stop-app dc-stop-mon dc-stop-log
dc-start: dc-start-app dc-start-mon dc-start-log

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
build-fluentd:
	cd logging/fluentd && docker build -t ${USER_NAME}/fluentd .


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
push-fluentd:
	docker push ${USER_NAME}/fluentd

dc-build-app: 
	cd docker/ && docker-compose build
dc-build-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml build
dc-build-log:
	cd docker/ && docker-compose -f docker-compose-logging.yml  build
dc-up-app: 
	cd docker/ && docker-compose up -d
dc-up-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml up -d
dc-up-log:
	cd docker/ && docker-compose -f docker-compose-logging.yml  up -d
dc-down-app: 
	cd docker/ && docker-compose down
dc-down-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml down
dc-down-log:
	cd docker/ && docker-compose -f docker-compose-logging.yml  down
dc-stop-app: 
	cd docker/ && docker-compose stop
dc-stop-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml stop
dc-stop-log:
	cd docker/ && docker-compose -f docker-compose-logging.yml  stop
dc-start-app: 
	cd docker/ && docker-compose start
dc-start-mon:
	cd docker/ && docker-compose -f docker-compose-monitoring.yml start
dc-start-log:
	cd docker/ && docker-compose -f docker-compose-logging.yml  start

dm-create:
	docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-address static-ip \
    --google-zone europe-west1-b \
    --google-preemptible \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging
	echo 'Run - eval $$(docker-machine env logging)'

dm-rm:
	docker-machine rm logging
	echo 'Run - eval $$(docker-machine env -u)'