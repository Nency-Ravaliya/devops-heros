![alt text](image.png)
![alt text](image-1.png)

### hello_ci.yml
name: Hello GitHub Actions
on:
  push:
    branches:
      - main
      - feature/*
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Print message
        run: echo "Hello from GitHub Actions!"
      - name: Show date
        run: date
      - name: Show operating system
        run: uname -a
      - name: Print my name
        run: echo "namae wa Piyush desu!"
  secrets-demo:
    runs-on: ubuntu-latest
    steps:
      - name: Check secret
        env:
          DEMO_SECRET: ${{ secrets.DEMO_SECRET }}
        run: |
          if [ -n "$DEMO_SECRET" ]; then
            echo "Secret is available."
          else
            echo "Secret is not configured."
            exit 1
          fi
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Run build
        run: |
          chmod +x build.sh
          ./build.sh
      - name: Show build files
        run: |
          echo "Build output:"
          ls -la build
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: session16-build
          path: build/

