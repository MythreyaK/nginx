# NGINX  
[![Build Status](https://pink-panther98.visualstudio.com/Nginx/_apis/build/status/MythreyaK.nginx?branchName=master)](https://pink-panther98.visualstudio.com/Nginx/_build/latest?definitionId=5&branchName=master)

A minimal NGINX image compiled with security flags and TLS 1.3 support for 
fast and secure docker containers. Built with most modules nginx supports. 
Final docker image size with libraries is ~22MB. 

This image features an nginx binary with Read only relocation (`Full RELRO`), 
Stack protection (`canary`), No Execute on data (`NX`), Address space randomization 
`Full ASLR`, Buffer Overflow checks (`FORTIFY_SOURCE`) and replaced server tokens 
(`Server: nignx/ver` to `Server: server/ver`)* HTTP header and support for the 
latest HTTPS (`TLS 1.3`) protocol.

Master process runs as `root` user, worker processes as `nginx`.  
<sub>* Custom fields are available when building from Dockerfile with CLI options. 
DockerHub image uses a generic `server/1.0` token. </sub>

## Package versions
|Package|Version|
|---|---|
|NGINX|`1.16.0`|
|OpenSSL|`1.1.1.b`|  
|PCRE|`8.43`|
|Zlib|`1.2.11`|
|LibGD|`2.2.5`|

## How to use
To build the docker image yourself, just clone this repo and run 
`docker build -t <name:tag>` and `docker run -p <host:container> <name:tag>`.  

A Docker image is available at `mythreyak/nginx` on [Docker Hub](https://hub.docker.com/r/mythreyak/nginx). 
Pull the image with `docker pull mythreyak/nginx:<tag>`.
