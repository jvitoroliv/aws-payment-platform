# Description

[Jira User Story](https://example-org.atlassian.net/browse/PROJ-[TICKET_NUMBER])

Summary of the work included in this PR:

* What resources were added/modified/deleted
* Any configuration changes?

# Summary of Changes

- change_1_here
- change_2_here

## PR Creator Checklist

- [ ] Added unit tests
- [ ] Added one of the following labels (patch, minor, major)
- [ ] Added or updated documentation
- [ ] Confirmed that `terraform plan` in CI looks correct

## To Test

```shell
go test ./terraform/modules/tag-allowlist/validation/
```

## PR Reviewer Checklist

- [ ] Download the branch and test locally
- [ ] Before signing off, write a comment on the PR explaining your understanding of the code
- [ ] I have reviewed this code to ensure it is developed according to secure coding guidelines, which includes, but is
  not limited to, checking for the items listed below:
  ### OWASP 2021 Top 10
    - A01:2021 - Broken Access Control
    - A02:2021 - Cryptographic Failures
    - A03:2021 - Injection
    - A04:2021 - Insecure Design
    - A05:2021 - Security Misconfiguration
    - A06:2021 - Vulnerable and Outdated Components
    - A07:2021 - Identification and Authentication Failures
    - A08:2021 - Software and Data Integrity Failures
    - A09:2021 - Security Logging and Monitoring Failures
    - A10:2021 - Server-Side Request Forgery


