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
2. [Initial configuration](#initial-configuration)  
3. [Running the build workflow](#run-build-workflow)  
4. [Try the promotion workflow](#try-promotion-workflow)  
5. [Configure missing evidences](#configure-missing-evidences)
   1. Configre Approval evidence
   2. Configure Sbom evidence
6. [Re-Run the promotion workflow](#run-promotion-workflow)
7. Bonus step: [Add approver validation](#add-approver-validation)

***
**Note**
For more information about evidence on the JFrog platform, see the following resources:
* [Help center](https://jfrog.com/help/r/evidence-management/evidence-management)
* [GitHub public evidence examples](https://github.com/jfrog/Evidence-Examples)
* [Evidence solution sheet](https://drive.google.com/file/d/16BIn_PR9mR-KzvMAoWi-n_1HmUfhRiAW/view?usp=sharing)
* [Training Deck](https://docs.google.com/presentation/d/1nZWFAMEOdW9n1uCNQiIVJSOFrsWGQfs-JNjydP5sxwM/edit?usp=sharing)
* [FAQ page](https://docs.google.com/document/d/1Yzodo2Nl3XsRQYXxAzW0yidrG9XqbqmJc-DYrpVdiGE/edit?usp=sharing)
* [Evidence service confluence space](https://jfrog-int.atlassian.net/wiki/spaces/DPCP/pages/981631021/Evidence+Knowledge+Transfer)

For more information related to OPA (Open Policy Agent) see the following resources:
* [OPA help center](https://www.openpolicyagent.org/docs/latest/)
* [OPA policy language guide](https://www.openpolicyagent.org/docs/latest/policy-language/)
* [OPA Playground](https://play.openpolicyagent.org/)
***

## 1. Prerequisites {#prerequisites}

* Create a dedicated OCI repository in [solenglatest.jfrog.io](https://solenglatest.jfrog.io) and assign it to DEV environment.
* Create another dedicated OCI repository in [solenglatest.jfrog.io](https://solenglatest.jfrog.io) and assign it to QA environment.
* Create a evidence signing key using the following commands:
  ```
  openssl genrsa -out private.pem 2048
  openssl rsa -in private.pem -pubout -out public.pem
  ```
*  Upload the public key to [solenglatest.jfrog.io](https://solenglatest.jfrog.io) using the [public keys](https://jfrog.com/help/r/jfrog-platform-administration-documentation/manage-public-keys) screen.
   * Use pbcopy to copy the public key to the artifactory UI to make sure no special characters are copied, for example:
     ```
     cat public.pem | pbcopy
     ```
***
## 2. Initial configuration  {#initial-configuration}

In this step you will configure your environment to be able to run the evidence github workflow we will be using throughout the training

1. Fork the evidence-enablement repository.
2. Add your name as a prefix to the build name, in the build.yml file.
3. Update the REPO_NAME variable in th build.yml workflow file to the OCI dev repository you have created.
4. Add the following github actions variables/secrets:
   1. Variables:
      1. ARTIFACTORY_URL - https://solenglatest.jfrog.io.
   2. Secrets:
      1. ARTIFACTORY_ACCESS_TOKEN - generate an access token (Not a reference token) to be used by docker login.
      3. PRIVATE_KEY - The evidence signing key you have generated as part of preparing to the training.
      2. KEY_ALIAS - the alias of the public key you uploaded to the platform.
      4. RB_KEY - a signing key that will be used to sign the Release bundle (If you do not have one you can use `evidence-demo-rbv2-key`).

***
## 3. Running the build workflow {#run-build-workflow}

In this step we will run the build workflow for the first time and review the results.

1. Navigate to the build workflow, and run it.
2. Review the build summery and see which steps and resources were created as part of the workflow.
3. Navigate to the release bundle in the JFrog platform using the link in the summary page.
4. Navigate to the evidence graph tab and review the evidences, created as part of this build.
5. Make sure that all evidences were verified using the public key.

***
## 4. Try the promotion workflow {#try-promotion-workflo}

In this step you will try to promote the release bundle to QA.

1. Navigate to the promote workflow, and run it. You should pass an existing release bundle number as an input to the workflow.
2. Check if the workflow completed successfully.
3. If it did not try and figure out why the workflow failed by reviewing the following files:
   1. ./github/build.yml
   2. ./github/promote.yml
   3. ./scripts/graphql.sh
   4. ./scripts/graphql_query.gql
   5. ./policy/policy.rego

***
## 5. Configure missing evidences {#configure-missing-evidences}

In this step we will configur the missing evidences so the workflow can path the policy validation.

1. Uncomment the `Approve release-bundle` step in the build workflow.
2. Enable Xray indexing for the release bundle created by the build workflow.

***
## 6. Re-Run the promotion workflow {#run-promotion-workflow}

In this step we will re-run the promotion workflow again, after adding all of the evidences expected by the policy.

1. Navigate to the build workflow, and run it again.
4. Make sure the workflow completese successfully.
6. Navigate to the release bundle in the JFrog platform using the link in the summary page.
7. Navigate to the evidence graph tab and review the evidences, created as part of the updated build.
3. Check that all of the relevan evidences were created successfully, you should see approval evidence and SBOM evidence attached to the release bundle.
4. Navigate to the promote workflow, and run it again.
5. Make sure the workflow completese successfully.
8. Review the approval evidence content, and check which data is included in the evidence. Where is this data comming from?

***
***
## 7. Bonus step: Add approver validation {#add-approver-validation}

In this step we will add a validation who can approve the release bundle.
Currently the workflow sets the approver in the approval evidence to be the actor running the workflow, but this can be changed to a human approver, based on input parameters.

1. Navigate to the policy under: `./policy/policy.rego`
2. Edit the policy file and uncomment the approver policy lines (23-26, 31, 38)
4. Navigate to the promote workflow, and run it. It will fail.
5. Check why the policy failed (look at the workflow run log).
4. Change the approver name in line 31 to your github user name (This is the default actor running the workflows in github).
5. 4. Navigate to the promote workflow, and run it again. Now the approval should pass.

