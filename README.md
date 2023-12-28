# aa-aws-terraform-demo

## Requirements

**Functional/Architectural Requirements:**
 
Deliver four backend endpoints (no front end, no HTML) that will be the start of user management for a new application.  The endpoints shall create, read, update, and delete new users.  The properties of a user object are left up to you. Enable appropriate authentication and validation on these endpoints. The user’s data shall be stored in DynamoDB with primary and sort keys named ‘_pk0’ and _’sk0’ respectively. Deployment of these APIs can be provided through your preferred Infrastructure-As-Code framework.
 
**Required AWS services:**
- API Gateway
- DynamoDB
 
**Prohibited AWS services:**
- Lambda
 
**All other AWS services optional per your design.**
 
**Deliveries:**
- IAC code to deploy.
- Instructions so we can deploy and test the solution.
- Postman file we can use to exercise the deployed endpoints

## Development

### Setup

This repo uses Python 3.9 for development of the Fargate code. Assuming you have [Pyenv properly installed](https://github.com/pyenv/pyenv#set-up-your-shell-environment-for-pyenv), run these commands at CLI (I used `zsh 5.9` on MacOS):

1. Ensure Python 3.9 is installed globally
    ```
    pyenv install 3.9
    ```
1. Ensure Python 3.9 is the global installation
    ```
    pyenv global 3.9
    ```
1. Verify the correct Python version is configured
    ```
    python --version # Should echo `Python 3.9.XX`
    ```
1. Create the virtual environment
    ```
    cd app
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```