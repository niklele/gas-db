docker run -p 5432:5432 --name gas-db -e POSTGRESS_PASSWORD=password -d postgres
docker start $(docker ps -l -q)
docker exec -it $(docker ps -l -q) psql -U postgres