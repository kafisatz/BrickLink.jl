# syntax = docker/dockerfile:1.2
#choose a base image
#FROM julia:1.9.4-alpine #alpine has no apt (but apk)

FROM julia:1.10.5-bookworm

# mark it with a label, so we can remove dangling images
LABEL cicd="bricklink"

#https://vsupalov.com/buildkit-cache-mount-dockerfile/
ENV PIP_CACHE_DIR=/var/cache/buildkit/pip
RUN mkdir -p $PIP_CACHE_DIR
RUN rm -f /etc/apt/apt.conf.d/docker-clean
#RUN --mount=type=cache,target=/var/cache/apt apt-get update && apt-get install -yqq --no-install-recommends wget git iputils-ping && rm -rf /var/lib/apt/lists/*

ENV TZ="Europe/Zurich" USER=root USER_HOME_DIR=/home/${USER} JULIA_DEPOT_PATH=${USER_HOME_DIR}/.julia NOTEBOOK_DIR=${USER_HOME_DIR}/notebooks JULIA_NUM_THREADS=1

####################################
#Install python and pip 
RUN apt-get update
#RUN apt-get install -y software-properties-common gcc
#RUN apt-get update 

#install pkg
#https://stackoverflow.com/questions/77028925/docker-compose-fails-error-externally-managed-environment
#RUN pip3 install uptime-kuma-api --break-system-packages
#RUN pip3 install playwright --break-system-packages
#RUN playwright install-deps

#copy Julia package 
RUN mkdir -p /usr/local/BrickLink.jl
COPY . /usr/local/BrickLink.jl

#set workdir
WORKDIR /usr/local/BrickLink.jl

#install dependencies 
RUN julia /usr/local/BrickLink.jl/deps/dockerdeps.jl
 
#exports
EXPOSE 8003

########################################################################
#enviroment variables
########################################################################
ARG ConsumerKey
ENV ConsumerKey $ConsumerKey

ARG ConsumerSecret
ENV ConsumerSecret $ConsumerSecret

ARG TokenValue
ENV TokenValue $TokenValue

ARG TokenSecret
ENV TokenSecret $TokenSecret

ARG influxtoken
ENV influxtoken $influxtoken

#https://stackoverflow.com/questions/75668905/adding-secret-to-docker-build-from-environment-variable-rather-than-a-file
#RUN --mount=type=secret,id=my_secret_id \
# export MY_SECRET=$(cat /run/secrets/my_secret_id) && \
# echo $MY_SECRET # would output "foo"
########################################################################
#run Tests
########################################################################
#RUN julia --project=@. -e "import Pkg;Pkg.test()"

########################################################################
#run application 
########################################################################
USER root
#start julia script
#ENTRYPOINT ["julia", "-p 1"]
ENTRYPOINT ["julia"]
CMD ["src/infinite_loop.jl"]
#CMD ["src/dummy.jl"]
#working dir is set as bricklink.jl