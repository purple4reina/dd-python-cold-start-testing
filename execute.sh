#!/bin/bash

# Optional arguments
# REGION: AWS region (default: sa-east-1)
# ACCOUNT: AWS account ID (default: 425362996713)
# FUNCS: Space-separated list of function names (default: python-ab-test-dev-before python-ab-test-dev-after)
# URLS: Space-separated list of URLs (default: empty, will be gathered using aws cli)

if [[ -z $REGION ]]; then
    REGION=sa-east-1
fi

if [[ -z $ACCOUNT ]]; then
    ACCOUNT=425362996713
fi

if [[ -z $FUNCS ]]; then
    FUNCS="python-ab-test-dev-before python-ab-test-dev-after"
fi

if [[ -z $URLS ]]; then
    echo Gathering URLs using aws cli
    for f in $FUNCS
    do
        URLS="$URLS $(
            aws lambda get-function-url-config \
                --function-name "$f" \
                --region $REGION \
                --output json | jq -r '.FunctionUrl'
        )"
    done
    echo "Found URLs: $URLS"
fi

update_memory() {
    funcname=$1
    aws lambda update-function-configuration \
        --function "arn:aws:lambda:$REGION:$ACCOUNT:function:$funcname" \
        --region $REGION \
        --memory-size $(( RANDOM % 64 + 1024 )) \
        --query MemorySize
}

while true
do
    for f in $FUNCS
    do
        update_memory "$f" &
    done
    wait

    sleep 2

    for u in $URLS
    do
        for _ in {1..100}
        do
            (
                for _ in {1..2}
                do
                    curl "$u"
                    sleep 0.1
                done
            ) &
        done
    done
    wait
done
