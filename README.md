# RLM/Evidence training

Artifactory enables you to attach evidence (signed metadata) to a designated subject, such as an artifact, build, package, or Release Bundle v2. These evidence files provide a record of an external process performed on the subject, such as test results, vulnerability scans, or official approval.

In this training we will exrsize the process of attaching different types of evidences, including:

* Package evidence
* Build evidence
* Release Bundle evidence
* Approval evidence
* CyclonDX evidence

We will also experience validating the existing evidences, and apply an OPA (Open Policy Engine) policy in order to control the Release bundle promotion flow

These are the steps we will cover suring our training:

1. [Prerequisites](#prerequisites)
2. [Initial configuration](#initial-preparations)  
3. [Running the build workflow](#run-build-workflow)  
4. [Try the promotion workflow](#try-promotion-workflow)  
5. [Configure missing evidences](#configure-missing-evidences)
   1. [Configre Approval evidence](#configure-approval-evidences)
   2. [Configure Sbom evidence](#configure-sbom-evidences)
6. [Run the promotion workflow](#run-promotion-workflow)  

***
**Note**
For more information about evidence on the JFrog platform, see the following resources:
* [Help center](https://jfrog.com/help/r/evidence-management/evidence-management)
* [GitHub public evidence examples](https://github.com/jfrog/Evidence-Examples)
* [Evidence solution sheet](https://drive.google.com/file/d/16BIn_PR9mR-KzvMAoWi-n_1HmUfhRiAW/view?usp=sharing)
* [Training Deck](https://docs.google.com/presentation/d/1nZWFAMEOdW9n1uCNQiIVJSOFrsWGQfs-JNjydP5sxwM/edit?usp=sharing)
* [FAQ page](https://docs.google.com/document/d/1Yzodo2Nl3XsRQYXxAzW0yidrG9XqbqmJc-DYrpVdiGE/edit?usp=sharing)
* [Evidence service confluence space](https://jfrog-int.atlassian.net/wiki/spaces/DPCP/pages/981631021/Evidence+Knowledge+Transfer)
***

## Prerequisites {#prerequisites}

* Create a dedicated docker repository in [solenglatest.jfrog.io](https://solenglatest.jfrog.io)
* Create a evidence signing key using the following steps:
   *  openssl genrsa -out private.pem 2048
   *  openssl rsa -in private.pem -pubout -out public.pem
*  Upload the public key to [solenglatest.jfrog.io](https://solenglatest.jfrog.io) using the [public keys](https://jfrog.com/help/r/jfrog-platform-administration-documentation/manage-public-keys) screen
   * Use pbcopy to copy the public key to the artifactory UI to make sure no special characters are copied
     (eg. ```cat public.pem | pbcopy```

## 

## Bootstrapping  {#bootstrapping}

### Install JFrog CLI {#install-jfrog-cli}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) installs the latest version of the JFrog CLI and performs checkout. Please note that a valid access token is required. 

```
jobs:  
  Docker-build-with-evidence:  
    runs-on: ubuntu-latest  
    steps:  
      - name: Install jfrog cli  
        uses: jfrog/setup-jfrog-cli@v4  
        env:  
          JF_URL: ${{ vars.ARTIFACTORY_URL }}  
          JF_ACCESS_TOKEN: ${{ secrets.ARTIFACTORY_ACCESS_TOKEN }}

      - uses: actions/checkout@v4
```

### Log In to the Artifactory Docker Registry {#log-in-to-the-artifactory-docker-registry}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) logs into the Docker registry, as described in the [prerequisites](#prerequisites), and sets up QEMU and Docker Buildx in preparation for building the Docker image.

```
 - name: Log in to Artifactory Docker Registry  
   uses: docker/login-action@v3  
   with:  
     registry: ${{ vars.ARTIFACTORY_URL }}  
     username: ${{ secrets.JF_USER }}  
     password: ${{ secrets.ARTIFACTORY_ACCESS_TOKEN }}

 - name: Set up QEMU  
   uses: docker/setup-qemu-action@v3

 - name: Set up Docker Buildx  
   uses: docker/setup-buildx-action@v3  
   with:  
     platforms: linux/amd64,linux/arm64  
     install: true
```

## Build the Docker Image {#build-the-docker-image}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) builds the Docker image and deploys it to Artifactory.

```
 - name: Build Docker image  
   run: |  
     URL=$(echo ${{ vars.ARTIFACTORY_URL }} | sed 's|^https://||')  
     REPO_URL=${URL}'/example-project-docker-dev-virtual'  
     docker build --build-arg REPO_URL=${REPO_URL} -f Dockerfile . \  
     --tag ${REPO_URL}/example-project-app:${{ github.run_number }} \  
     --output=type=image --platform linux/amd64 --metadata-file=build-metadata --push  
     jfrog rt build-docker-create example-project-docker-dev --image-file build-metadata --build-name ${{ vars.BUILD_NAME }} --build-number ${{ github.run_number }}
```

## Attach Package Evidence {#attach-package-evidence}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) creates evidence for the package containing the Docker image. The evidence is signed with your private key, as defined in the [Prerequisites](#prerequisites).

```
- name: Evidence on docker  
  run: |  
     echo '{ "actor": "${{ github.actor }}", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'" }' > sign.json  
     jf evd create --package-name example-project-app --package-version 32 --package-repo-name example-project-docker-dev \  
       --key "${{ secrets.PRIVATE_KEY }}" \  
       --predicate ./sign.json --predicate-type https://jfrog.com/evidence/signature/v1   
     echo ' Evidence attached: `signature` ' 
```

## Upload README File and Associated Evidence {#upload-readme-file-and-associated-evidence}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) uploads the README file and creates signed evidence about this generic artifact. The purpose of this section is to demonstrate the ability to create evidence for any type of file uploaded to Artifactory, in addition to packages, builds, and Release Bundles.

```
- name: Upload readme file  
  run: |  
    jf rt upload ./README.md example-project-generic-dev/readme/${{ github.run\_number }}/ --build-name ${{ vars.BUILD_NAME }} --build-number ${{ github.run_number }}  
    jf evd create --subject-repo-path example-project-generic-dev/readme/${{ github.run_number }}/README.md \  
      --key "${{ secrets.PRIVATE_KEY }}" \  
      --predicate ./sign.json --predicate-type https://jfrog.com/evidence/signature/v1
```

## Publish Build Info and Attach Build Evidence {#publish-build-info-and-attach-build-evidence}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) creates a build from the package containing the Docker image and then creates signed evidence attesting to its creation.

```
  - name: Publish build info  
    run: jfrog rt build-publish ${{ vars.BUILD_NAME }} ${{ github.run_number }}

  - name: Sign build evidence  
    run: |  
      echo '{ "actor": "${{ github.actor }}", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'" }' > sign.json  
      jf evd create --build-name ${{ vars.BUILD_NAME }} --build-number ${{ github.run_number }} \
        --predicate ./sign.json --predicate-type https://jfrog.com/evidence/build-signature/v1 \
        --key "${{ secrets.PRIVATE_KEY }}"  
      echo ' Evidence attached: `build-signature` ' >> $GITHUB_STEP_SUMMARY
```

## Create a Release Bundle v2 from the Build {#create-a-release-bundle-v2-from-the-build}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) creates an immutable Release Bundle v2 from the build containing the Docker image. Having a Release Bundle prevents any changes to the Docker image as it progresses through the various stages of your SDLC towards eventual distribution to your end users.

```
- name: Create release bundle  
  run: |  
    echo '{ "files": [ {"build": "'"${{ vars.BUILD_NAME }}/${{ github.run_number }}"'" } ] }' > bundle-spec.json  
    jf release-bundle-create ${{ vars.BUNDLE_NAME }} ${{ github.run_number }} --signing-key PGP-RSA-2048 --spec bundle-spec.json --sync=true  
    NAME_LINK=${{ vars.ARTIFACTORY_URL }}'/ui/artifactory/lifecycle/?bundleName='${{ vars.BUNDLE_NAME }}'&bundleToFlash='${{ vars.BUNDLE_NAME }}'&repositoryKey=example-project-release-bundles-v2&activeKanbanTab=promotion'  
    VER_LINK=${{ vars.ARTIFACTORY_URL }}'/ui/artifactory/lifecycle/?bundleName='${{ vars.BUNDLE_NAME }}'&bundleToFlash='${{ vars.BUNDLE_NAME }}'&releaseBundleVersion='${{ github.run_number }}'&repositoryKey=example-project-release-bundles-v2&activeVersionTab=Version%20Timeline&activeKanbanTab=promotion'  
    echo ' Release bundle ['${{ vars.BUNDLE_NAME }}']('${NAME_LINK}'):['${{ github.run_number }}']('${VER_LINK}') created' >> $GITHUB_STEP_SUMMARY
```
***
**Note**

For more information about using the JFrog CLI to create a Release Bundle, see [https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/release-lifecycle-management](https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/release-lifecycle-management).
***

## Attach Release Bundle Evidence {#attach-release-bundle-evidence}

This section of [build.yaml](https://github.com/jfrog/Evidence-Examples/tree/main/.github/workflows) creates signed evidence about the Release Bundle. 

```
 - name: Evidence on release-bundle v2  
   run: |  
     echo '{ "actor": "${{ github.actor }}", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'" }' > rbv2_evidence.json  
     JF_LINK=${{ vars.ARTIFACTORY_URL }}'/ui/artifactory/lifecycle/?bundleName='${{ vars.BUNDLE_NAME }}'&bundleToFlash='${{ vars.BUNDLE_NAME }}'&releaseBundleVersion='${{ github.run_number }}'&repositoryKey=release-bundles-v2&activeVersionTab=Version%20Timeline&activeKanbanTab=promotion'  
     echo 'Test on Release bundle ['${{ vars.BUNDLE_NAME }}':'${{ github.run_number }}']('${JF_LINK}') success' >> $GITHUB_STEP_SUMMARY  
     jf evd create --release-bundle ${{ vars.BUNDLE_NAME }} --release-bundle-version ${{ github.run_number }} \  
       --predicate ./rbv2_evidence.json --predicate-type https://jfrog.com/evidence/rbv2-signature/v1 \  
       --key "${{ secrets.PRIVATE_KEY }}"  
     echo ' Evidence attached: integration-test ' >> $GITHUB_STEP_SUMMARY  
```
