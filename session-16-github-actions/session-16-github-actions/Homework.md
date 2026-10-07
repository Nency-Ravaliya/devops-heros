# Session 16: CI/CD & GitHub Actions

**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062  

---

## 1. Project Overview

This project demonstrates a complete **CI/CD pipeline using GitHub Actions** for a Python Calculator application.

The project covers the complete development and automation workflow, including:

- Application development
- Automated testing using Pytest
- Application build process
- Docker containerization
- GitHub Actions
- CI and CD concepts
- Workflows
- Jobs and Steps
- GitHub-hosted Runners
- GitHub Secrets
- Build Artifacts
- Automated pipeline execution

The objective of the project is to demonstrate how changes pushed by a developer can automatically trigger testing, building, artifact generation, Docker image creation, and validation.

---

## 2. CI vs CD

### Continuous Integration (CI)

Continuous Integration is the practice of automatically validating code whenever developers push changes to a shared repository.

In this project, the CI pipeline performs:

1. Source code checkout
2. Python environment setup
3. Dependency installation
4. Automated testing using Pytest
5. Application build
6. Build artifact generation

If the tests fail, the later dependent stages do not proceed.

### Continuous Delivery (CD)

Continuous Delivery extends CI by preparing and validating the application in a deployable form.

In this project, the CD stage:

1. Builds the Docker image
2. Verifies the generated Docker image
3. Runs the application inside a Docker container
4. Performs container validation
5. Confirms successful completion of the delivery pipeline

This ensures that only successfully tested and built application code reaches the Docker delivery stage.

---

## 3. CI/CD Pipeline Architecture

The complete pipeline used in this project is:

```text
Developer
    |
    | git push
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    v
+-----------------------------+
| CI - Test Application       |
|-----------------------------|
| Checkout Source Code        |
| Verify GitHub Secret        |
| Setup Python                |
| Install Dependencies        |
| Run Pytest                  |
+-----------------------------+
              |
              | Tests Passed
              v
+-----------------------------+
| CI - Build Application      |
|-----------------------------|
| Checkout Source Code        |
| Execute build.sh            |
| Generate Build Files        |
| Upload Build Artifact       |
+-----------------------------+
              |
              | Build Passed
              v
+-----------------------------+
| CD - Build Docker Image     |
|-----------------------------|
| Checkout Source Code        |
| Build Docker Image          |
| Verify Docker Image         |
| Test Docker Container       |
| Validate CD Completion      |
+-----------------------------+
              |
              v
      PIPELINE SUCCESS
```

The jobs are dependent on each other, ensuring that a failure in an earlier stage prevents an invalid application from progressing further through the pipeline.

---

## 4. Project Structure

```text
session16-cicd-github-actions/
│
├── app/
│   ├── __init__.py
│   └── calculator.py
│
├── tests/
│   └── test_calculator.py
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
├── ss/
│   └── Successful execution screenshots
│
├── Dockerfile
├── requirements.txt
├── build.sh
├── .gitignore
└── README.md
```

The `ss/` directory contains the relevant screenshots captured during successful local and GitHub Actions pipeline execution.

---

## 5. Application Source Code

The application is a Python-based calculator.

It implements mathematical operations including:

- Addition
- Subtraction
- Multiplication
- Division
- Power

Example:

```python
def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

def power(a, b):
    return a ** b
```

The application can also be executed interactively from the terminal.

Example:

```bash
python3 app/calculator.py
```

Example calculation:

```text
Enter calculation: 10 + 5
Result: 15.0
```

---

## 6. Automated Testing

Automated testing is implemented using **Pytest**.

The test suite validates:

```text
test_add
test_subtract
test_multiply
test_divide
test_divide_by_zero
test_power
```

Tests can be executed locally using:

```bash
pytest -v
```

Successful execution confirms that the application behaves as expected before the build stage is allowed to execute.

Example result:

```text
test_add PASSED
test_subtract PASSED
test_multiply PASSED
test_divide PASSED
test_divide_by_zero PASSED
test_power PASSED
```

The division-by-zero test additionally verifies exception handling.

---

## 7. Build Process

The project contains a `build.sh` script for automating the application build process.

Execute it using:

```bash
chmod +x build.sh
./build.sh
```

The script:

- Removes the previous build directory
- Creates a fresh build directory
- Copies the application into the build directory
- Generates build information
- Confirms successful completion

Generated build output:

```text
build/
├── calculator.py
└── build-info.txt
```

The build information contains details such as:

```text
Application: Session 16 Calculator
Build Status: SUCCESS
Build Date: <build-date>
```

This provides a reproducible build process that can be executed both locally and by GitHub Actions.

---

## 8. Docker Containerization

A `Dockerfile` is included to package the application inside a Docker container.

The image uses Python 3.12 and contains the application and its required dependencies.

Build the Docker image using:

```bash
docker build -t calculator-app:v1 .
```

Verify the image:

```bash
docker images | grep calculator-app
```

Run the application inside the container:

```bash
docker run --rm -it calculator-app:v1
```

Example:

```text
Enter calculation: 10 + 5
Result: 15.0
```

Docker provides a consistent runtime environment and makes the successfully tested application portable.

---

## 9. GitHub Actions

GitHub Actions is used to automate the complete CI/CD process.

The workflow configuration is stored at:

```text
.github/workflows/ci-cd.yml
```

The workflow is configured to execute on repository events such as pushes to the `main` branch and can also support manual execution through `workflow_dispatch`.

A GitHub Actions workflow consists of:

```text
Workflow
   |
   +--- Job
   |     |
   |     +--- Step
   |     +--- Step
   |     +--- Step
   |
   +--- Job
         |
         +--- Step
         +--- Step
```

This project separates testing, building, and Docker delivery into different jobs so that each stage of the pipeline is clearly visible.

---

## 10. Workflow

The GitHub Actions workflow automates the project from source-code validation to Docker image validation.

The workflow contains three primary jobs:

```text
CI - Test Application
        |
        v
CI - Build Application
        |
        v
CD - Build Docker Image
```

The dependent execution order prevents later stages from running successfully unless the required earlier stages have completed.

---

## 11. Jobs

### Job 1: CI - Test Application

The test job is responsible for validating application functionality.

It performs:

```text
Checkout Source Code
        ↓
Verify GitHub Secret
        ↓
Setup Python
        ↓
Install Dependencies
        ↓
Run Tests
```

If testing fails, the dependent build job cannot proceed successfully.

### Job 2: CI - Build Application

The build job executes after successful testing.

It performs:

```text
Checkout Source Code
        ↓
Run build.sh
        ↓
Display Build Output
        ↓
Upload Build Artifact
```

This converts successfully tested source code into a build output.

### Job 3: CD - Build Docker Image

The CD job executes after successful completion of the build stage.

It performs:

```text
Checkout Source Code
        ↓
Build Docker Image
        ↓
Verify Docker Image
        ↓
Run/Test Container
        ↓
Confirm CD Completion
```

This verifies that the application can successfully operate inside its containerized runtime environment.

---

## 12. Steps

Each GitHub Actions job consists of individual **steps**.

Examples of steps used in this project include:

- Checking out repository source code
- Setting up Python
- Accessing the configured GitHub Secret
- Installing project dependencies
- Running Pytest
- Executing the build script
- Listing generated build files
- Uploading the build artifact
- Building a Docker image
- Inspecting the Docker image
- Running the Docker container
- Validating pipeline completion

Breaking the workflow into steps makes pipeline execution easier to understand, debug, and verify.

---

## 13. GitHub Actions Runner

The jobs execute on a GitHub-hosted runner:

```yaml
runs-on: ubuntu-latest
```

A runner is the machine responsible for executing workflow jobs.

For every workflow execution, GitHub provides the environment required to execute commands such as:

```text
python
pip
pytest
bash
docker
```

Using a GitHub-hosted runner removes the need to maintain a separate CI/CD server.

---

## 14. GitHub Secrets

GitHub Secrets are used to securely store sensitive values required by workflows.

A repository secret named:

```text
DEMO_SECRET
```

was configured through:

```text
Repository
→ Settings
→ Secrets and variables
→ Actions
→ Repository secrets
```

The workflow accesses it securely through GitHub Actions rather than hardcoding the secret value in source code.

Example:

```yaml
env:
  DEMO_SECRET: ${{ secrets.DEMO_SECRET }}
```

The workflow validates that the secret is available without exposing its actual value:

```bash
if [ -z "$DEMO_SECRET" ]; then
  echo "Secret is not configured"
  exit 1
fi

echo "GitHub Secret accessed successfully"
```

### Security Consideration

The actual secret value is **not committed to the Git repository and is not printed in workflow logs**.

This demonstrates the correct principle of separating sensitive configuration from source code.

---

## 15. Build Artifacts

After successful testing and building, GitHub Actions uploads the generated build directory as an artifact.

Artifact name:

```text
calculator-build
```

Artifact contents include the generated application build files.

The artifact provides a downloadable output associated with a specific successful workflow execution.

Pipeline flow:

```text
Source Code
    ↓
Tests
    ↓
Build
    ↓
build/
    ↓
Upload Artifact
    ↓
calculator-build
```

This makes build outputs traceable to individual CI/CD runs.

---

## 16. Pipeline Execution

The pipeline is automatically triggered when changes are pushed to the configured `main` branch.

Typical execution:

```bash
git add .
git commit -m "Update application"
git push origin main
```

After the push:

```text
Git Push
    ↓
GitHub Repository
    ↓
GitHub Actions Triggered
    ↓
CI - Test Application
    ↓
CI - Build Application
    ↓
CD - Build Docker Image
    ↓
SUCCESS
```

A successful workflow confirms that the application passed the required automated validation stages.

---

## 17. Pipeline Dependency and Failure Protection

An important feature of this project is that pipeline stages are dependent on successful completion of previous stages.

The dependency is:

```text
Test
  ↓
Build
  ↓
Docker/CD
```

Therefore:

```text
Test Failure
     ↓
Build Does Not Proceed Successfully
     ↓
CD Does Not Proceed
```

Similarly:

```text
Test Passed
     ↓
Build Passed
     ↓
Docker Validation Passed
     ↓
Pipeline SUCCESS
```

This prevents faulty code from progressing through the delivery pipeline.

---

## 18. Screenshots / Execution Evidence

All relevant execution screenshots are stored in the:

```text
ss/
```

directory.

The screenshots provide evidence of successful project execution, including relevant stages such as:

- Local application execution
- Successful Pytest execution
- Application build
- Docker image build
- Docker container execution
- GitHub Actions workflow execution
- Successful CI test job
- Successful build job
- Successful CD/Docker job
- GitHub Secret verification
- Build artifact generation/upload
- Complete successful pipeline execution

These screenshots provide visual evidence that the implementation was executed practically rather than only documented theoretically.

---

## 19. Technologies Used

| Technology | Purpose |
|---|---|
| Python | Application development |
| Pytest | Automated testing |
| Bash | Build automation |
| Docker | Application containerization |
| Git | Version control |
| GitHub | Source code repository |
| GitHub Actions | CI/CD automation |
| GitHub Secrets | Secure configuration |
| GitHub Artifacts | Build output storage |
| Ubuntu Runner | Workflow execution environment |

---

## 20. Complete Development Workflow

The complete workflow followed in this project is:

```text
1. Develop Python Application
              ↓
2. Write Automated Tests
              ↓
3. Run Tests Locally
              ↓
4. Build Application
              ↓
5. Build and Test Docker Image
              ↓
6. Commit Source Code
              ↓
7. Push to GitHub
              ↓
8. GitHub Actions Triggered
              ↓
9. CI Test Job
              ↓
10. CI Build Job
              ↓
11. Upload Build Artifact
              ↓
12. CD Docker Job
              ↓
13. Docker Image Validation
              ↓
14. Pipeline SUCCESS
```

---

## 21. Deliverables

| Deliverable | Implementation | Status |
|---|---|---|
| Application Source Code | `app/calculator.py` | ✅ Completed |
| Automated Tests | `tests/test_calculator.py` | ✅ Completed |
| Dockerfile | `Dockerfile` | ✅ Completed |
| GitHub Actions Workflow | `.github/workflows/ci-cd.yml` | ✅ Completed |
| CI Pipeline | Test + Build jobs | ✅ Completed |
| CD Pipeline | Docker build and validation job | ✅ Completed |
| GitHub Secrets | `DEMO_SECRET` | ✅ Completed |
| Build Artifact | `calculator-build` | ✅ Completed |
| Build Automation | `build.sh` | ✅ Completed |
| Pipeline Execution | GitHub Actions | ✅ Completed |
| Screenshots | `ss/` directory | ✅ Completed |
| Documentation | `README.md` | ✅ Completed |

---

## 22. Key Learning Outcomes

Through this project, I gained practical experience with:

- Understanding the difference between CI and CD
- Creating CI/CD pipelines using GitHub Actions
- Writing GitHub Actions workflow YAML
- Organizing workflows into jobs and steps
- Using job dependencies
- Working with GitHub-hosted runners
- Running automated tests in CI
- Automating application builds
- Creating and uploading build artifacts
- Containerizing applications with Docker
- Building and validating Docker images automatically
- Securely accessing GitHub Secrets
- Triggering pipelines through Git operations
- Debugging and verifying automated pipeline execution

---

## 23. Conclusion

This project successfully demonstrates an end-to-end **CI/CD workflow using GitHub Actions**.

The application is automatically tested before being built, ensuring that incorrect code cannot proceed through the pipeline. After successful testing, the application is built and stored as a GitHub Actions artifact. The subsequent CD stage builds and validates a Docker image, demonstrating how a tested application can be prepared in a portable and reproducible form.

The project also demonstrates important GitHub Actions concepts including **workflows, jobs, steps, runners, secrets, artifacts, testing, builds, job dependencies, and automated pipeline execution**.

The successful GitHub Actions runs and supporting screenshots stored in the `ss/` directory provide practical evidence that the complete pipeline was implemented and executed successfully.

---

## Final Result

```text
Application Source Code       ✅
Automated Testing             ✅
Build Automation              ✅
Dockerfile                    ✅
Docker Containerization       ✅
GitHub Actions                ✅
Workflow                      ✅
Jobs                          ✅
Steps                         ✅
Runner                        ✅
GitHub Secrets                ✅
Build Artifacts               ✅
CI Pipeline                   ✅
CD Pipeline                   ✅
Pipeline Execution            ✅
Execution Screenshots         ✅
Documentation                 ✅

          CI/CD PIPELINE SUCCESSFUL
```

---

**Session 16 — CI/CD & GitHub Actions**  
**Submitted by: Ankita Tripathi**  
**Roll Number: 24BCS10062**