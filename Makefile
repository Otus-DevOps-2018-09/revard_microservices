default: build push

build: build_comment build_post build_ui build_prometheus build_cloudprober

push: push_comment push_post push_ui push_prometheus push_cloudprober

build_comment:
	cd src/comment && bash docker_build.sh
build_post:
	cd src/post-py && bash docker_build.sh
build_ui:
	cd src/ui && bash docker_build.sh
build_prometheus:
	cd monitoring/prometheus && docker build -t ${USER_NAME}/prometheus .
build_cloudprober:
	cd monitoring/cloudprober && docker build -t ${USER_NAME}/cloudprober .

push_comment:
	docker push ${USER_NAME}/comment
push_post:
	docker push ${USER_NAME}/post
push_ui:
	docker push ${USER_NAME}/ui
push_prometheus:
	docker push ${USER_NAME}/prometheus
push_cloudprober:
	docker push ${USER_NAME}/cloudprober

dc-build: 
	cd docker/ && docker-compose build
dc-up: 
	cd docker/ && docker-compose up -d
dc-down: 
	cd docker/ && docker-compose down
dc-stop: 
	cd docker/ && docker-compose stop
dc-start: 
	cd docker/ && docker-compose start

