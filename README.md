# The Sentinel Ledger Project

A fast and incorruptible payment processing engine. Intended to be able to support a huge amount of requests; and at the same time, to guarantee no transaction can be altered without leaving a fingerprint.

## The Big Picture
Three services that talk to each other:

- **The Server:**  The main app, receives the money transfers and saves them into a database
- **The Blitz:**   A script that floods the server with thousands of requests to test its endurance.
- **The Auditor:** A detective script that scans the database and finds out if it has been corrupted.

***  
