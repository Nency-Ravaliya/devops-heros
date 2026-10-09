# LabTrack video walkthrough

This order follows the instructor's final demo list. A 7 to 10 minute recording is enough if each result is shown clearly.

## Before recording

From session21-final-devops-project:

~~~bash
docker compose up --build -d
cd monitoring && docker compose up -d && cd ..
~~~

Open these pages before recording:

- http://localhost:3000
- http://localhost:8000/docs
- http://localhost:9091/targets
- http://localhost:3001/d/labtrack-final

## Recording order and speaking notes

1. **Introduce the project**
   - Say: “This is LabTrack, my DevOps practice journal. I changed the application domain and built the full workflow around it.”
   - Show the main page and the four status cards.

2. **Create and update a lab**
   - Click **Plan a lab**.
   - Add a Kubernetes or monitoring lab.
   - Use the arrow button to change its status.
   - Delete a temporary lab to demonstrate the final CRUD operation.

3. **Show Swagger**
   - Open /docs.
   - Expand GET /api/labs and run it.
   - Point out POST, GET by ID, PUT, and DELETE.
   - Also show /health, /ready, and /metrics.

4. **Show PostgreSQL**
   - Run:

     ~~~bash
     docker compose exec postgres psql -U labtrack -d labtrack \
       -c "select id,title,tool,difficulty,status from labs order by id;"
     ~~~

   - Say: “The data shown in React is stored in PostgreSQL.”

5. **Run tests**
   - Run pytest -v from backend.
   - Point out that eight tests pass and cover more than three endpoints.

6. **Show containers**
   - Run docker compose ps.
   - Show the backend and frontend image users with docker image inspect.
   - Say: “Both application containers run as non-root users, and the frontend uses a multi-stage build.”

7. **Show Git and GitHub Actions**
   - Run git log --oneline -10.
   - Open the successful Session 21 workflow.
   - Open the two Trivy steps and the GHCR package pages.
   - Say: “The pipeline tests, scans, publishes commit-SHA images, deploys to Kind, and smoke-tests the service.”

8. **Show Terraform**
   - Run terraform validate.
   - Show main.tf and terraform.tfvars.example.
   - Say clearly: “I validated the code locally. I did not apply it because this account has no AWS credits and EKS creates paid resources.”

9. **Show Kubernetes and Helm**
   - Run:

     ~~~bash
     kubectl get pods,svc,ingress,pvc,hpa -n labtrack
     helm list -n labtrack
     ~~~

   - Show at least two frontend and two backend Pods running.
   - Open the application through the port-forward or Ingress.

10. **Show monitoring**
    - Open the Prometheus targets page and show labtrack-backend as UP.
    - Open Grafana and point out health, request rate, memory, latency, and response status.

11. **Show troubleshooting**
    - Apply the broken image and show ImagePullBackOff, then fix it.
    - Apply the broken Service and show an empty EndpointSlice, then correct the selector.
    - Explain how events and labels led to each fix.

12. **Finish**
    - Say: “LabTrack now has a tested application, container delivery, Kubernetes packaging, monitoring, and repeatable troubleshooting. The AWS apply is the one part I could not run without paid credits.”

## Recording tip

Keep the terminal font large and hide unrelated windows. Pause briefly after each command so the result can be read. Do not show passwords, tokens, or browser account settings.
