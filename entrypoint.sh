#!/bin/bash

# Command-line arguments
token_id=$1
token=$2
org=$3
db=$4
branch=${5:-$(date +%Y%m%d%H%M%S)}
command=$6

# Make sure authentication arguments aren't empty
if [[ -z "$token_id" || -z "$token" ]]; then
    echo "The \"planetscale-service-token-id\" and \"planetscale-service-token\" values cannot be empty."
    exit 1
fi

# Set the org
pscale org switch "$org"

# Create the branch and wait for readiness
pscale branch create "$db" "$branch" --wait

# Connect to the branch and run the migrations
pscale connect "$db" "$branch" --execute "$command"

# Create the deploy request and get the number
number=$(pscale deploy-request create "$db" "$branch" --format json | jq -r '.number')

# Wait for the deploy request to be deployable
while true; do
    # Check the deploy request deployment for "deployable" property
    deployable=$(pscale deploy-request show "$db" "$number" --format json | jq -r '.deployment.deployable')

    if [[ "$deployable" == "true" ]]; then
        echo "Deploy request #$number is now deployable."
        break
    fi

    count=$((count+1))

    # Check that we haven't exceeded 30 tries
    if [[ "$count" -ge 30 ]]; then
        echo "Deploy request #$number is not deployable after $count retries. Exiting..."
        exit 1
    fi

    echo "Deploy request #$number is not yet deployable. Checking again soon."

    # Wait 10 seconds before trying again
    sleep 10
done

# Check the deployment state
state=$(pscale deploy-request show "$db" "$number" --format json | jq -r '.deployment.state')

# Deploy, if ready
case $state in
    "ready")
        pscale deploy-request deploy "$db" "$number" --wait
        ;;

    "no_changes")
        echo "No schema changes were detected."
        ;;

    *)
        echo "Unknown deployment state: $state returned. Exiting..."
        exit 1
esac

# Delete the branch once deployed
pscale branch delete "$db" "$branch" --force
