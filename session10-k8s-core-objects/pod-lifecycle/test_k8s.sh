#!/bin/bash

NAMESPACE="default"
TIMEOUT=30
SCREENSHOTS_DIR="screenshots/task_1"

mkdir -p "$SCREENSHOTS_DIR"

# Get all yaml files sorted by name
YAML_FILES=$(ls *.yaml 2>/dev/null | sort)

for file in $YAML_FILES; do
    echo -e "\n========================================"
    echo "  Applying: $file"
    echo "========================================"

    # Clean up any leftover resources from previous file
    kubectl delete -f "$file" --ignore-not-found --wait=false 2>/dev/null

    # Apply
    kubectl apply -f "$file"
    if [ $? -ne 0 ]; then
        echo "  ✗ Failed to apply $file"
        continue
    fi

    # Get the pod name
    sleep 2
    POD=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' | head -1)

    if [ -z "$POD" ]; then
        echo "  ✗ No pod found"
        continue
    fi

    echo "  Pod: $POD"

    # Wait for pod to reach a stable state
    for i in $(seq 1 $TIMEOUT); do
        STATUS=$(kubectl get pod "$POD" -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $3}')
        case "$STATUS" in
            Running|Succeeded|Failed|ImagePullBackOff|ErrImagePull|CrashLoopBackOff|Init:CrashLoopBackOff|Init:Error|ContainerCreating|Pending)
                break
                ;;
        esac
        sleep 1
    done

        # Clear screen, then print clean output for screenshot
    clear
    echo "========================================"
    echo "  $file"
    echo "========================================"
    echo "  Status: $STATUS"
    kubectl get pod "$POD" -n "$NAMESPACE"
    if [ "$STATUS" != "Running" ] && [ "$STATUS" != "Succeeded" ]; then
        echo "  --- Events ---"
        kubectl describe pod "$POD" -n "$NAMESPACE" | grep -A 20 "Events:"
    fi

    echo ""
    echo "  Press Enter to capture screenshot..."
    read -r _
    gnome-screenshot -w -f "${SCREENSHOTS_DIR}/${file%.yaml}.png"   
    # Clean up
    kubectl delete -f "$file" --ignore-not-found --wait=false 2>/dev/null
    sleep 2

done

echo -e "\n========================================"
echo "  All done. Screenshots saved to $SCREENSHOTS_DIR/"
echo "========================================"   
