# gchat

## Description

gchat notifications functionality

<pre>
steps:
- name: Send Message
  uses: example-org/shared-actions/gchat
  with:
    version: 1.0.1
    message: 'Test Message'
    jobsuccessfull: 'Succeded'
    repositoryurl: 'https://github.com/example-org/ps-tag-test-harness'
    commiturl: 'https://github.com/example-org/ps-tag-test-harness/pull/90/commits/a62b39ee7a5d6a0f894be6e28497dd0b38162b50'
    branchname: 'PROJ-10950-new-stage-config'
    runurl: 'https://github.com/example-org/ps-tag-test-harness/actions/runs/11108581406'
    actor: 'zack'
    vault_webhook_url: 'dev/kvv2/webhookurl'
</pre>
![Success](./job_succeeded.png)

<pre>
steps:
- name: Send Message
  uses: example-org/shared-actions/gchat
  with:
    version: 1.0.1
    message: 'Test Message'
    jobsuccessfull: 'Failed'
    repositoryurl: 'https://github.com/example-org/ps-tag-test-harness'
    commiturl: 'https://github.com/example-org/ps-tag-test-harness/pull/90/commits/a62b39ee7a5d6a0f894be6e28497dd0b38162b50'
    branchname: 'PROJ-10950-new-stage-config'
    runurl: 'https://github.com/example-org/ps-tag-test-harness/actions/runs/11108581406'
    actor: 'zack'
    vault_webhook_url: 'dev/kvv2/webhookurl'
</pre>

![Failed](./job_failed.png)

<pre>
steps:
- name: Send Message
  uses: example-org/shared-actions/gchat
  with:
    version: 1.0.1
    message: 'Test Message'
    jobsuccessfull: 'Deployment triggered'
    repositoryurl: 'https://github.com/example-org/ps-tag-test-harness'
    commiturl: 'https://github.com/example-org/ps-tag-test-harness/pull/90/commits/a62b39ee7a5d6a0f894be6e28497dd0b38162b50'
    branchname: 'PROJ-10950-new-stage-config'
    runurl: 'https://github.com/example-org/ps-tag-test-harness/actions/runs/11108581406'
    actor: 'zack'
    vault_webhook_url: 'dev/kvv2/webhookurl'
</pre>

![Deployment_triggered](./Deployment_triggered.png)

## Inputs

| name                | description                                                                               | required | default  |
|---------------------|-------------------------------------------------------------------------------------------|----------|----------|
| `version`           | <p> action for automated tagging</p>                                                      | `true`   | `""`     |
| `message`           | <p>message to appear in Google chat</p>                                                   | `true`   | `""`     |
| `jobsuccessfull`    | <p>Whether the run was successful or not. Takes only Two values True Or False</p>         | `true`   | `"true"` |
| `repositoryurl`     | <p>URL of the Repository</p>                                                              | `true`   | `""`     |
| `commiturl`         | <p>URL of the latest git commit</p>                                                       | `true`   | `""`     |
| `branchname`        | <p>branch name which triggered the job</p>                                                | `true`   | `""`     |
| `runurl`            | <p>URL of the github Job</p>                                                              | `true`   | `""`     |
| `actor`             | <p>Name of the person whose action triggered</p>                                          | `true`   | `""`     |
| `vault_webhook_url` | <p>Create a new vault secret with key webhook_url and value is the gchat webhook _url</p> | `true`   | `""`     |
