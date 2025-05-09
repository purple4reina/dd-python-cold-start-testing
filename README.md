# dd-python-cold-start-testing

A simple test app with dashboard for performing before/after comparisons of
`dd-trace-py` changes

This guide will walk you through creating lambda layers with unpublished
versions of `dd-trace-py` and `datadog-lambda-python`. You will then deploy two
lambda functions you wish to compare and execute them. Lastly, you'll be able
to view results in a custom dashboard.

## Setup

Before you get started, let's gather all your configuration options into
environment variables. This way you'll be able to just copy and paste the
commands below without needing to edit them.

1. AWS Account. Determine which account you wish to use. You will need both the
   account number and the SSO name. If you don't know the latter, check your
   `~/.aws/config` file.

    ```bash
    $ export ACCOUNT=1234567890
    $ export ACCOUNT_NAME=sso-your-account-name-admin
    ```

1. DataDog API Key. Choose where you want to send your DataDog metrics. Create
   or grab an existing api key from that account.

    ```bash
    $ export DD_API_KEY=1234567890abcdefghijklmnopqrstuvwxyz
    ```

1. AWS Region. Set which region you wish to use. When in doubt, use
   `us-east-1`.

    ```bash
    $ export REGION=us-east-1
    ```

1. Suffix. This step is optionally but recommended. It will make sure all the
   resources you deploy to AWS are unique to you. Let's not step on other's
   toes.

    ```bash
    $ export SUFFIX=your-name-here
    ```

There are other optional configuration options not listed here. The scripts
[`publish.sh`](publish.sh) and [`execute.sh`](execute.sh) will list all
available options at the top of their files.

You will want these environment variables to be set for all the commands you
will execute in your terminal.

## Deploy

### Publish testing lambda layers

This will certainly be the trickiest step in the process of using this repo.
But fear not, I'll walk you through it. Once you've done it once, it will be
easier every other time.

1. Check out both [`dd-trace-py`](https://github.com/DataDog/dd-trace-py) _and_
   [`datadog-lambda-python`](https://github.com/DataDog/datadog-lambda-python)
   repos to your laptop.

1. Make your change to either `dd-trace-py` or `datadog-lambda-python`. Commit
   and push those changes.

1. Run the publish script. Replace the `dd-trace-py` branch you used above, if
   you didn't make changes to `ddtrace`, then you can leave the argument blank.

    ```bash
    $ aws-vault exec $ACCOUNT_NAME -- ./publish.sh <dd-trace-py-branch>
    ```

1. Take note of the AWS Lambda Layer ARN printed to stdout by the publish
   script. You will use this arn in the steps below.

### Deploying to AWS Lambda

1. You will use [Serverless Framework](https://www.serverless.com/) to deploy
   your lambda stack.  To install, run

    ```bash
    $ npm install serverless@"<4.0.0" -g
    ```

    Also install our serverless plugin which will be used to install our
    datadog instrumentation.

    ```bash
    $ serverless plugin install -n serverless-plugin-datadog
    ```

1. Update layer versions on the before and after functions in the
   [serverless.yml](serverless.yml) file. These can either be publicly
   available layers or ones you deployed yourself above.

    For reference, you can always find the arns for the most recently released
    python layer on the [datadog-lambda-python releases
    page](https://github.com/DataDog/datadog-lambda-python/releases).

1. Deploy the stack.

    ```bash
    $ aws-vault exec $ACCOUNT_NAME -- sls deploy
    ```

## Execute

You're probably mostly interested in seeing differences in cold start times
between layer versions. This means you'll probably want to have a lot of cold
starts to compare. You can do this by calling the execute script

```bash
$ aws-vault exec $ACCOUNT_NAME -- ./execute.sh
```

Let the script run for 5-10 minutes or more to produce enough data.

## Analyze

If you're using the `ddserverless` DataDog org, then you can use the ["Rey's
Awesome Purple Dashboard"](https://ddserverless.datadoghq.com/dashboard/5yn-x2m-2ne/reys-awesome-purple-dashboard?fromUser=false&refresh_mode=paused&from_ts=1746664500908&to_ts=1746664800908&live=false&tile_focus=4418579574713790)
to view the results.

If you're using DataDog org 2, then you can use the ["Python Performance AB
Testing"](https://app.datadoghq.com/dashboard/r8i-pu9-u8z?fromUser=false&refresh_mode=sliding&from_ts=1746811143076&to_ts=1746814743076&live=true) dashboard to view the results.

Otherwise, you can create a new DataDog dashboard using the provided
`dashboard.json` file.

Note that you may need to update the `before-funcname` and `after-funcname`
dashboard variable at the top of the page. By default, the `serverless.yml`
file will deploy your functions as `python-ab-test-dev-before` and
`python-ab-test-dev-after` respectively.

![img](dashboard.png)
