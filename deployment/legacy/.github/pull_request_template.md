- [ ] Linked to Jira Item [ENC-xxx]  Note: Update xxx to correct Jira Card number
- [ ] Please review for OWASP Top 10  vulnerabilities, and ONLY approve the pull request if no related issues were identified.
        - Injection
        - Broken Authentication and Session Management
        - Sensitive Data Exposure
        - XML External Entities (XXE)
        - Broken Access Control
        - Security Misconfiguration
        - Cross-Site Scripting (XSS)
        - Insecure Deserialization
        - Using Components with Known Vulnerabilities
        - Insufficient Logging & Monitoring
- [ ] Please review for the following code compliance
        - Modifying Enums (always put new members at the end; don’t renumber)
                - Removing enums (without defined values) could cause issues.
        - Selective Deployment (any non-standard deployment items like batches, etc?) (_SelectiveDeploymentGroups.xml should have the right components selected for the changes being made), Here is the document that provide information about this tool. https://docs.google.com/document/d/1uFbnO6WzK3Yc7wLLGbDLrH_EJmdv5SGca9xZHLze6YA/edit#
- [ ] Please review for the following database compliance
        - Adding a non-nullable column to a large table (make column nullable)
        - Altering a column on a large table
        - Modifying a stored procedure signature (always add optional parameters at the end)
        - Dropping a column (take two releases to do this)
                - Should only be done in pre-schema.
                - If the Linq2Sql type from the DBML is being referenced, test that the column can be dropped without the DBML being updated.
        - Long-running data population scripts in release.sql (review first run against FINSERV UAT using the deployment events)
        - Adding indexes to large tables (should be done outside of release in non-disruptive manner)
        - Alter column statements should not be present in the pre or post sql files.
        - Ensure all changes are compliant with Safe Database Changes

# Pull Request
copilot:summary