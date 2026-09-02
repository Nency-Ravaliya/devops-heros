# Docker Resources

- https://docs.docker.com/get-started/docker-overview/
- https://www.geeksforgeeks.org/devops/architecture-of-docker/

docker stop $(docker ps -q)
    docker ps -q → gets IDs of running containers
    docker stop → stops them

docker rm $(docker ps -aq)

* docker ps -aq → gets IDs of all containers, including stopped ones
* docker rm → removes them

Force remove all containers

If you want to stop + remove all containers in one command:

docker rm -f $(docker ps -aq)

3. Remove all Docker images
docker rmi $(docker images -q)

Force remove all images
docker rmi -f $(docker images -q)


For a complete Docker cleanup:
docker system prune -a



