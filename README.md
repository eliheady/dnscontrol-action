# dnscontrol-action

The **experimental** Github Action (GHA) for DNSControl

> [!NOTE]
> _This project is experimental and not yet recommended for use in production or otherwise important workflows_

This is a composite GitHub action for running configurable DNSControl commands.

[DNSControl](https://dnscontrol.org) is an [opinionated](https://docs.dnscontrol.org/developer-info/opinions) platform for seamlessly managing your DNS configuration across any number of DNS hosts, both in the cloud or in your own infrastructure.

### Action Features

* Write DNSControl output to PRs, job summary, and/or a file of your choosing
* Run (or don't) a "preflight" `dnscontrol check` before your command; check failure will stop the job and write to the job summary
* Specify alternate locations for `dnsconfig.js` and `creds.json`
* Choose which version of DNSControl to run (the default is the latest release)

**Credentials**

You can pre-populate your `creds.json` file and pass in its path as an input, or you can set your API secrets in environment variables and rely on DNSControl's built-in variable interpolation to use variable values to authenticate to your providers.

> [!WARNING]
> Secret values may be exposed in job logs when using environment variables to pass secrets. GitHub masks known secret values but debug logs or errors in GitHub's masking implementation may expose secret values. In short, populate your `creds.json` secrets and avoid writing secrets to environment variables if possible.

**Inputs**

* **cmdargs**: The command and flags you want to run (required)
* **dnsconfig_file**: The alternate location of `dnsconfig.js` (optional)
* **creds_file**: The alternate location of `creds.json` (optional)
* **output_file**: The file into which the command output should be written (optional)
* **post_pr_comment**: Post the command output to a PR comment (true/false, default is false)
* **post_summary**: Post the command output to the running job summary (true/false, default is false)

**Outputs**

* **output**: The output from the dnscontrol command you specified
* **output_file**: The workspace file (if you specified) into which output from the dnscontrol command was written

**Usage Example**

Example with all inputs set:

```yaml
uses: eliheady/dnscontrol-composite-action
with:
  check: true
  cmdargs: preview --expect-no-changes
  creds_file: path/to/my-creds.json
  dnsconfig_file: path/to/my-dnsconfig.json
  output_file: dnscontrol-output.log
  post_pr_comment: true
  post_summary: true
```

**Simple DNSControl Preview Example**

Run `dnscontrol preview` from a PR:

```yaml
# yaml-language-server: $schema=https://json.schemastore.org/github-workflow.json

name: DNSControl

on:
  pull_request:
    paths:
      - '*dnsconfig.js'
      - '*creds.json'

permissions:
  contents: read
  pull-requests: write

jobs:
  preview:
    runs-on: ubuntu-latest
    if: ${{ !cancelled() }}
    steps:
      -
        name: Checkout repo
        uses: actions/checkout@08eba0b27e820071cde6df949e0beb9ba4906955 # v4.3.0
      -
        # add all secrets needed for creds.json variable interpolation
        name: Prepare creds_file
        run: |
          cat >creds-populated.json<<EOF
          {
            "route53": {
              "TYPE": "ROUTE53",
              "KeyId": "${{ secrets.DNSCONTROL_ROUTE53_KEY_ID }}",
              "SecretKey": "${{ secrets.DNSCONTROL_ROUTE53_KEY }}"
            }
          }
          EOF
      -
        # call the action with options to run `dnscontrol check` before `dnscontrol preview`,
        # post to the PR, and post to the job summary
        name: call dnscontrol action
        uses: eliheady/dnscontrol-composite-action@20815e1d394785504a8411889f845d9d16b8fed7 # v0.0.5
        with:
          cmdargs: preview
          post_pr_comment: true
          post_summary: true
          check: true
          creds_file: creds-populated.json
```

### Contributing

PRs welcome.

Changes or additions to the shell scripts in action.yml should pass `shellcheck -S warning`. A PR workflow will run a shellcheck wrapper (`bin/shellcheck.sh`) and any findings at warning or error levels will fail the check. The wrapper script has been tested in Bash 5.2 and zsh 5.9 on Linux and MacOS.
