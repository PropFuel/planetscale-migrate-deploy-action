#!/bin/bash

# Command-line arguments
org=$1
db=$2
branch=${3:-$(date +%Y%m%d%H%M%S)}
command=$4
delete=$5

# Make sure authentication environment variables are set
if [[ -z "$PLANETSCALE_SERVICE_TOKEN_ID" || -z "$PLANETSCALE_SERVICE_TOKEN" ]]; then
    echo "The \"PLANETSCALE_SERVICE_TOKEN_ID\" and \"PLANETSCALE_SERVICE_TOKEN\" environment variables must be set."
    exit 1
fi

# Create the branch and wait for readiness
pscale branch create "$db" "$branch" --org "$org" --wait

# Connect to the branch and run the migrations
pscale connect "$db" "$branch" --org "$org" --execute "$command"

# Create the deploy request and get the number
number=$(pscale deploy-request create "$db" "$branch" --org "$org" --format json | jq -r '.number')

# Wait for the deploy request to be deployable
while true; do
    # Check the deploy request deployment for "deployable" property
    deployable=$(pscale deploy-request show "$db" "$number" --org "$org" --format json | jq -r '.deployment.deployable')

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
state=$(pscale deploy-request show "$db" "$number" --org "$org" --format json | jq -r '.deployment.state')

# Deploy, if ready
case $state in
    "ready")
        pscale deploy-request deploy "$db" "$number" --org "$org" --wait
        ;;

    "no_changes")
        echo "No schema changes were detected."
        ;;

    *)
        echo "Unknown deployment state: $state returned. Exiting..."
        exit 1
esac

# Delete the branch once deployed
if [[ "$delete" == "true" || "$delete" == "True" || "$delete" == "TRUE" ]]; then
    pscale branch delete "$db" "$branch" --org "$org" --force
fi
