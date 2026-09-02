# Docker Networking

**Name:** Shivansh Singh  
**Enrollment Number:** 24BCS10050

## 1. Three-Container Architecture

The setup contains three containers:

- Frontend
- Backend
- Database

Three Docker networks are used:

- `frontend-net`
- `backend-net`
- `database-net`

The backend is connected to both the frontend and database networks.

```bash
docker network create frontend-net
docker network create backend-net
docker network create database-net

docker network connect frontend-net backend
docker network connect backend-net backend
docker network connect database-net database