APP_NAME ?= peoplesanspeople

PATH_INPUTS_BINDMOUNT_HOST ?= /home/$(USER)/Documents/yolov8_human_sim/yolov8/docker_run/$(YOLOv8_EXPERIMENT_NAME)
PATH_INPUTS_BINDMOUNT_CONTAINER ?= /usr/src/app/yolov8/runs

build: ## Build the container
	docker build --ssh default -t ${APP_NAME} .

build-nc: ## Build the container without caching
	docker build --ssh default --no-cache -t $(APP_NAME) .

build-run: ## Build and run container
	docker build --ssh default -t $(APP_NAME) . && docker run --shm-size 8G --gpus all -it --rm -v $(PATH_INPUTS_BINDMOUNT_HOST):$(PATH_INPUTS_BINDMOUNT_CONTAINER) --name="$(APP_NAME)" $(APP_NAME)

run: ## Run container
	docker run --shm-size 8G --gpus all -it --rm --name="$(APP_NAME)" $(APP_NAME)

run-bash: ## Run container with bash
	docker run --entrypoint '' --gpus all -it --rm --name="$(APP_NAME)" $(APP_NAME) bash

run-bm: ## Run container with bind mount directory
	docker run --entrypoint '' --gpus all -it --rm -v $(PATH_INPUTS_BINDMOUNT_HOST):$(PATH_INPUTS_BINDMOUNT_CONTAINER) --name="$(APP_NAME)" $(APP_NAME) bash

clean-container:
	docker stop $(APP_NAME)
	docker rm $(APP_NAME)

kub-tag-push:
	docker tag $(APP_NAME) 192.168.1.15:32000/$(APP_NAME)
	docker push 192.168.1.15:32000/$(APP_NAME):latest

kub-run-image:
	kubectl apply -f $(APP_NAME).yaml
	kubectl exec --stdin --tty $(APP_NAME) -- /bin/bash
