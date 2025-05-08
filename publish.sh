#!/bin/bash

# Optional arguments
# REGION: AWS region (default: sa-east-1)
# LAMBDA_PYTHON_DIR: Path to the datadog-lambda-python directory (default: ~/go/src/github.com/DataDog/datadog-lambda-python)
# SUFFIX: Suffix to append to the layer name (default: current mac user)
# PYVERSION: Python version (default: 3.12)
# ARCHITECTURE: Architecture (default: arm64)

if [[ -z $REGION ]]; then
    REGION=sa-east-1
fi

if [[ -z $LAMBDA_PYTHON_DIR ]]; then
    LAMBDA_PYTHON_DIR=~/go/src/github.com/DataDog/datadog-lambda-python
fi

if [[ -z $SUFFIX ]]; then
    SUFFIX=$(id -un)  # default to the current mac user
fi

if [[ -z "$PYVERSION" ]]; then
    PYVERSION=3.12
fi

if [[ -z "$ARCHITECTURE" ]]; then
    ARCHITECTURE=arm64
fi

DD_TRACE_BRANCH=$1
LAYER_NAME="Python${PYVERSION/3./3}-${SUFFIX}"
LAYER_ZIP=".layers/datadog_lambda_py-${ARCHITECTURE}-${PYVERSION}.zip"

cd $LAMBDA_PYTHON_DIR || exit 1

if [[ $DD_TRACE_BRANCH ]]; then
    echo "using ddtrace branch $DD_TRACE_BRANCH"
    EXPRESSION='s/ddtrace = .*/ddtrace = \{ git = "https:\/\/github.com\/DataDog\/dd-trace-py.git", branch = \"'"$DD_TRACE_BRANCH"'\" }/'
    sed -i '' -e "$EXPRESSION" "pyproject.toml"
fi

echo "building and zipping package files"
PYTHON_VERSION=${PYVERSION} ARCH=${ARCHITECTURE} ./scripts/build_layers.sh

echo "publishing layer"
layer_arn=$(
    aws lambda publish-layer-version --layer-name "$LAYER_NAME" \
        --description "Datadog Tracer Lambda Layer for Python" \
        --zip-file "fileb://$LAYER_ZIP" \
        --region "$REGION" \
        --output json \
            | jq -r '.LayerVersionArn')

echo "new python layer published $layer_arn"
