## Get

![alt text](screenshots/1a.png) 

![alt text](screenshots/1b.png) 

## Describe

![alt text](screenshots/2a.png) 

![alt text](screenshots/2b.png) 

## Logs

![alt text](screenshots/3.png) 

## Exec

![alt text](screenshots/4.png) 

## Events

![alt text](screenshots/5a.png) 

![alt text](screenshots/5b.png) 

![alt text](screenshots/5c.png) 

![alt text](screenshots/5d.png) 

## Crashloopbackoff

![alt text](screenshots/6a.png) 

![alt text](screenshots/6b.png) 

## Imagepullbackoff

![alt text](screenshots/7a.png) 

![alt text](screenshots/7b.png) 

## Pending pods

![alt text](screenshots/8.png) 

## Service dns troubleshooting

![alt text](screenshots/9a.png) 

![alt text](screenshots/9b.png) 

![alt text](screenshots/9c.png) 

## Mini project

![alt text](screenshots/mp1.png) 

![alt text](screenshots/mp2.png) 

![alt text](screenshots/mp3.png) 

![alt text](screenshots/mp4.png)

**Question 1: What is the Pod status?**

**Answer:** `ErrImagePull` (transitioning to / currently in `ImagePullBackOff`).

---

**Question 2: What is the actual error?**

**Answer:** `429 Too Many Requests` (HTTP status 429 when trying to fetch the manifest from Docker Hub: `unexpected status from HEAD request to [https://registry-1.docker.io/v2/library/nginx/manifests/this-tag-does-not-exist](https://registry-1.docker.io/v2/library/nginx/manifests/this-tag-does-not-exist): 429 Too Many Requests`).

---

**Question 3: Which command helped you find the reason?**

**Answer:** `kubectl describe pod project-broken-pod`

---

**Question 4: What is wrong with the image?**

**Answer:** There are two issues:

1. **Tag doesn't exist:** The tag `nginx:this-tag-does-not-exist` is invalid/non-existent.
2. **Rate limited:** Docker Hub is rate-limiting the image pull attempts (`429 Too Many Requests`), which happens frequently when pulling non-existent or unauthenticated images repeatedly.

---

**Question 5: How would you fix it?**

**Answer:**

1. Edit `broken-pod.yaml` and update the container image tag to a valid, existing tag (e.g., `nginx:latest` or `nginx:1.25`).
2. Re-apply the manifest:
```bash
kubectl apply -f broken-pod.yaml

```

![alt text](image.png)