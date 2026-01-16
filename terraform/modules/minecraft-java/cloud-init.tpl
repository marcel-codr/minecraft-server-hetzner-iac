#cloud-config
packages:
  - curl
  - ca-certificates

runcmd:
  - curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
  - docker pull ${docker_image}
  - docker run -d \
      --name ${container_name} \
      -e EULA=TRUE \
      -p 25565:25565 \
      ${docker_image}
