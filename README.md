# Adoption Development Environment

A docker based development environment for the adoption-cos-api services.

## Requirements

This is designed to work on Mac or Linux but has not been tested on Windows.

The following packages are required:

- docker
- docker-compose
- azure-cli
- postgres-client
- node.js and yarn
- java 11

Note that a VPN is required as this environment uses multiple services in the AAT environment.

Also, you will need access to azure key vault. Please contact a member of No Fault Divorce team to gain access.

## Set up

If you're running on macOS install the following via brew:

```bash
brew install coreutils azure-cli libpq
brew link --force libpq
brew install --cask docker
```

Make sure that Docker has been given at least **9GB** of RAM.

The init script will clone the adoption repositories into sub-folders, start the CCD services and import the definition file. Then environment will then shut down and be ready for use.

```bash
./bin/init.sh
```

Once this command finishes run:

```bash
cd adoption-web
yarn build
yarn start:docker
```

Once everything has started you will be able to use the logins found in the `.env` file for:

* http://localhost:3000 XUI Case manager: login `IDAM_CASEWORKER_USERNAME`/`PASSWORD`
* http://localhost:3001 adoption: login `IDAM_CITIZEN_USERNAME`/`PASSWORD`

## Usage

Please note that the Java APIs must be assembled with `./gradlew assemble` before starting the environment.

```bash
./bin/start.sh
```

You can then log in to XUI going to `http://localhost:3000/`.

To stop docker containers execute below script. This will bring down all docker containers.

```bash
./bin/stop.sh
```

The following accounts have been set up:

- TEST_CASE_WORKER_USER@mailinator.com
- DivCitizenUser@AAT.com
- DivCaseWorkerUser@AAT.com  
- TEST_SOLICITOR@mailinator.com

The password for these accounts is in your .env file.

### Updating the CCD definition file

Import changes to the CCD definition file by running:

```bash
./bin/ccd-import-definition.sh
```
Note: Plese have local docker configuration as per below image:
<img width="1037" alt="docker" src="https://user-images.githubusercontent.com/94961980/151612154-8d20d3ef-6fb6-4088-ab68-c1c12cda0cb8.png">
