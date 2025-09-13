# Github commands
yes and walk me through creating a feature branch called dev, switch to dev because am currently working in main. that is the only branch i have. so we can test the entire workflow
ChatGPT said:

Perfect 🚀 let’s do this step by step. Right now you only have main, so we’ll create a new feature branch called dev, switch to it, and push it to GitHub. That way your workflow can kick in with the scans → PR → plan → apply pipeline.

1. Make sure your repo is clean
git status


If you have changes, either commit them or stash them:

git add .
git commit -m "save work before branching"

2. Create and switch to the dev branch
git checkout -b dev


This does two things:

Creates a new branch named dev

Switches you onto it

Confirm:

git branch


👉 You should see:

* dev
  main

3. Push the new branch to GitHub
git push -u origin dev


The -u sets the upstream so that future git push and git pull commands will default to the dev branch.

4. Make a small change to trigger the workflow

Since your workflow runs scans only on non-main branches, let’s edit any .tf file or even just add a comment line. Example:

# test trigger for workflow


Commit & push:

git add .
git commit -m "test: trigger workflow from dev branch"
git push

5. Watch GitHub Actions

Go to your repo → Actions tab → you should see:

SonarCloud scan

TFLint

Checkov

Then create-pr job → automatically opening a PR from dev → main.

6. Approve PR → Terraform plan

Once the PR exists, GitHub will trigger terraform-plan. You’ll see the plan as an artifact/review item in the PR.

7. Merge PR → Terraform apply

After you approve and merge into main, the workflow will detect the push to main and run terraform-apply.



Best Practice CI/CD Flow (for Terraform + security)

Push to feature branch → Run Sonar + Lint + Checkov only (no Terraform).

PR to main → Run Sonar + Security checks again, then run Terraform Plan (upload plan as artifact).

Approval required → Reviewer checks plan + security results.

Merge to main → Run Terraform Apply automatically.

Manual only → Destroy job.

# First workflow
name: Terraform CI/CD Pipeline

on:
  workflow_dispatch: # manual trigger
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

env:
  TF_VAR_management_account_id: ${{ secrets.AWS_MANAGEMENT_ACCOUNT_ID }}
  TF_VAR_dev_account_id: ${{ secrets.AWS_DEV_ACCOUNT_ID }}
  AWS_REGION: us-east-1  # adjust if needed
  SONAR_PROJECT_KEY: tankofm-inter-region-tgw-project_dainmusty
  SONAR_ORGANIZATION: tankofm-inter-region-tgw-project

jobs:
  sonarcloud:
    name: Run SonarCloud Code Quality Scan
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install SonarCloud Scanner
        run: |
          curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
          unzip -q sonar-scanner.zip
          echo "$PWD/sonar-scanner-5.0.1.3006-linux/bin" >> $GITHUB_PATH

      - name: SonarCloud Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
            -Dsonar.organization=${SONAR_ORGANIZATION} \
            -Dsonar.branch.name=${GITHUB_REF_NAME} \
            -Dsonar.sources=. \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.login=$SONAR_TOKEN

  lint-security:
    name: Terraform Lint + Security Scan
    runs-on: ubuntu-latest
    needs: sonarcloud

    steps:
      - uses: actions/checkout@v4

      - name: Install TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

      - name: Run TFLint
        working-directory: env/dev
        run: tflint --init && tflint

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: env/dev
          framework: terraform
          quiet: true
          soft_fail: false   # fail pipeline on high severity issues

  terraform:
    name: Deploy Infra with Terraform
    runs-on: ubuntu-latest
    needs: lint-security

    steps:
      - uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Terraform Format Check
        working-directory: env/dev
        run: terraform fmt -check

      - name: Terraform Validate
        working-directory: env/dev
        run: terraform validate

      - name: Terraform Plan
        id: plan
        working-directory: env/dev
        run: terraform plan -out=tfplan

      - name: Upload Terraform Plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: env/dev/tfplan

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        working-directory: env/dev
        run: terraform apply --auto-approve

  terraform-destroy:
    name: Destroy Infra (Manual Only)
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    needs: terraform

    steps:
      - uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Terraform Destroy
        working-directory: env/dev
        run: terraform destroy --auto-approve


# Do you also want me to wire in GitHub environments + approvals (so Terraform Apply won’t run until someone approves it in GitHub UI)? That way it’s not just auto-apply on merge.

Perfect 👍 let’s add GitHub Environments with required reviewers so Terraform Apply won’t run automatically without an approval in the GitHub UI.

🔹 How Environments Work

You define an environment in your repo settings (e.g. dev, staging, prod).

You can require manual approvals or set rules (who can approve, wait times, secrets, etc).

A job that targets that environment will pause until approval is given.

🔹 Updated Workflow with environment
name: Terraform CI/CD Pipeline

on:
  workflow_dispatch: # manual trigger (for destroy, manual plan, etc.)
  push:
    branches-ignore:
      - main   # only scans on feature branches
  pull_request:
    branches:
      - main   # scans + plan on PRs to main

env:
  TF_VAR_management_account_id: ${{ secrets.AWS_MANAGEMENT_ACCOUNT_ID }}
  TF_VAR_dev_account_id: ${{ secrets.AWS_DEV_ACCOUNT_ID }}
  AWS_REGION: us-east-1
  SONAR_PROJECT_KEY: tankofm-inter-region-tgw-project_dainmusty
  SONAR_ORGANIZATION: tankofm-inter-region-tgw-project

jobs:
  sonarcloud:
    name: Run SonarCloud Code Quality Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install SonarCloud Scanner
        run: |
          curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
          unzip -q sonar-scanner.zip
          echo "$PWD/sonar-scanner-5.0.1.3006-linux/bin" >> $GITHUB_PATH
      - name: SonarCloud Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
            -Dsonar.organization=${SONAR_ORGANIZATION} \
            -Dsonar.branch.name=${GITHUB_REF_NAME} \
            -Dsonar.sources=. \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.login=$SONAR_TOKEN

  lint-security:
    name: Terraform Lint + Security Scan
    runs-on: ubuntu-latest
    needs: sonarcloud
    steps:
      - uses: actions/checkout@v4
      - name: Install TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
      - name: Run TFLint
        working-directory: env/dev
        run: tflint --init && tflint
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: env/dev
          framework: terraform
          quiet: true
          soft_fail: false

  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    needs: lint-security
    steps:
      - uses: actions/checkout@v4
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false
      - name: Terraform Plan
        working-directory: env/dev
        run: terraform plan -out=tfplan
      - name: Upload Terraform Plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: env/dev/tfplan

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: lint-security
    environment:
      name: production  # 🔑 requires approval in repo settings
    steps:
      - uses: actions/checkout@v4
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false
      - name: Terraform Apply
        working-directory: env/dev
        run: terraform apply --auto-approve

  terraform-destroy:
    name: Destroy Infra (Manual Only)
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    environment:
      name: production  # 🔑 approval before destroy
    steps:
      - uses: actions/checkout@v4
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false
      - name: Terraform Destroy
        working-directory: env/dev
        run: terraform destroy --auto-approve

🔑 Next Steps for You

Go to Repo Settings → Environments → New Environment → call it production.

Under Protection Rules, require reviewers (e.g., yourself + another teammate).

When someone merges to main:

Terraform Apply job pauses.

GitHub shows “Waiting for approval in environment: production”.

Reviewer approves → job continues.

MULTI-VPC-INTER-REGION-TGW/
├── .github/workflows/
│   └── terraform-pipeline.yml
├── env/
│   └── dev/
│       ├── main.tf
│       └── variables.tf
├── modules/
│   └── vpc/
│   └── tgw/
├── sonar-project.properties   <-- place it here
└── .gitignore

# put this in sonar-project.properties to ingnore deprecated resources
# Ignore the "S3 bucket missing ACL/logging" rule
sonar.issue.ignore.multicriteria=e1
sonar.issue.ignore.multicriteria.e1.ruleKey=terraform:S3_LOGGING_ACL
sonar.issue.ignore.multicriteria.e1.resourceKey=**/*.tf

# Ignore wildcard Resource issue (logs:CreateLogGroup etc.)
sonar.issue.ignore.multicriteria+=e2
sonar.issue.ignore.multicriteria.e2.ruleKey=terraform:WILDCARD_RESOURCE
sonar.issue.ignore.multicriteria.e2.resourceKey=**/*.tf

# or adjust the workflow to incluse sonar ignore of some deprecated resources
- name: SonarCloud Scan
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  run: |
    sonar-scanner \
      -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
      -Dsonar.organization=${SONAR_ORGANIZATION} \
      -Dsonar.branch.name=${GITHUB_REF_NAME} \
      -Dsonar.sources=. \
      -Dsonar.host.url=https://sonarcloud.io \
      -Dsonar.login=$SONAR_TOKEN \
      -Dsonar.issue.ignore.multicriteria=e1,e2 \
      -Dsonar.issue.ignore.multicriteria.e1.ruleKey=terraform:S3_LOGGING_ACL \
      -Dsonar.issue.ignore.multicriteria.e1.resourceKey=**/*.tf \
      -Dsonar.issue.ignore.multicriteria.e2.ruleKey=terraform:WILDCARD_RESOURCE \
      -Dsonar.issue.ignore.multicriteria.e2.resourceKey=**/*.tf

# Double scanner is on, comes with errors, see below
Got it 👍 — that error means SonarCloud is trying to scan twice:

Automatic Analysis (enabled by default in SonarCloud UI).

Your GitHub Actions scanner job (the one you wrote in your workflow).

SonarCloud doesn’t allow both at the same time, so it fails with:

ERROR: You are running CI analysis while Automatic Analysis is enabled. 
Please consider disabling one or the other.

✅ Fix

Since you want full control in GitHub Actions (with security scans + PR gating), the best approach is:

Disable Automatic Analysis in SonarCloud:

Go to SonarCloud
.

Open your project → Administration → Analysis Method.

Turn off Automatic Analysis.

Save.

Now only the workflow’s sonar-scanner will run, and this error goes away.

🔄 Alternative (if you don’t want to disable Auto Analysis)

Remove the sonarcloud job from your workflow, and let SonarCloud’s automatic analysis run on every push.

Downside: you lose the ability to make scans part of your CI/CD gating logic (e.g., needs: sonarcloud).

👉 Since you already integrated Sonar into your CI/CD pipeline, I recommend disabling Automatic Analysis in SonarCloud UI and keeping your workflow-based scanner.

Do you want me to also tweak your workflow so Sonar runs only on pull requests, not on feature-branch pushes? That way you don’t get extra noise during early dev.



That formatting looks good 👍 — Checkov supports a .checkov.yaml or .checkov.yml file with a top-level key skip-check as a list.

Yours is valid YAML ✅, but I’d suggest two small tweaks for best practice:

Keep indentation consistent (2 spaces is the norm).

Align the comments so they’re clean and easier to read.

Here’s the polished version:

skip-check:
  - CKV2_AWS_62   # Event notifications not required for log bucket
  - CKV_AWS_290   # Acceptable write access in dev for flow logs
  - CKV_AWS_145   # Allowing all actions on all resources
  - CKV_AWS_144   # Cross-region replication not required for dev logs
  - CKV2_AWS_11   # VPC flow logs are handled dynamically in Terraform


💡 Tip: If you want these skips to apply only to Terraform checks, you can scope it with:

framework: terraform

skip-check:
  - CKV2_AWS_62
  - CKV_AWS_290
  - CKV_AWS_145
  - CKV_AWS_144
  - CKV2_AWS_11


This way, if later you add Docker/Kubernetes scans, the skips won’t “bleed over” into them.


SonarQube (Code Quality & Security in App Code)

Focus: Application code (Python, Java, Node, etc.).

Catches: Bugs, code smells, duplicated code, unit test coverage, OWASP issues in code.

Weak at: Infrastructure-as-Code (Terraform, CloudFormation, Kubernetes manifests).


🔹 Checkov (Security/Compliance in IaC)

Focus: Infrastructure-as-Code security and compliance.

Catches: Misconfigured S3 buckets, permissive IAM, insecure SGs, missing encryption, etc.

Weak at: Business logic, code maintainability, unit tests.

# tips for cicd workflow practices.

🔹 Best Practice

✅ Keep Checkov in the workflow (at least for IaC).
Even though you now run it locally via VS Code, CI/CD still needs it to:

Block insecure misconfigs from being merged.

Provide consistent security reporting across the team.

Catch issues if someone skips local scanning.

✅ Keep SonarCloud for code quality/security.
They complement each other (app vs infra).

🔄 Optimize your workflow so it’s not too slow:

You can run Checkov only on changed directories/files (e.g., only run when *.tf changes).

Run SonarCloud on every PR since code always changes.

🔹 Recommended Workflow Setup

Local: Use VS Code Checkov for fast feedback.

CI/CD: Run both:

SonarCloud → app code quality/security.

Checkov → Terraform/K8s/IaC misconfigs.

Branch Policy: PR must pass both before merge.

⚡ TL;DR: Don’t remove Checkov from CI — local scans help you fix earlier, but CI scans enforce team-wide security/compliance.
✅ This will:

Run SonarCloud always (since code always changes).

Run Checkov + TFLint only if .tf files changed in the commit/PR.

Speed up builds when infra code isn’t touched.




🔑 id-token: write

Lets the workflow request an OpenID Connect (OIDC) token from GitHub’s identity provider.

You usually need this when you’re setting up federated authentication with a cloud provider (e.g., AWS, Azure, GCP).

Example: instead of storing long-lived AWS keys in secrets, you configure AWS IAM to trust GitHub’s OIDC provider. Then your job can assume a role using id-token: write.

📦 packages: write

Grants permission to publish packages to GitHub Packages (npm, Docker images, Maven, etc.).

Without this, you can still download packages but can’t push new ones.

📂 contents: read

Lets the workflow read repository contents.

This is the bare minimum for most jobs (so actions/checkout can fetch your code).

If you want the workflow to push commits, open PRs, or tag releases, you’d usually need contents: write.

⚡ Typical setup

For Terraform + security scans, you normally don’t need packages: write.
But if you’re:

Publishing Docker images → you’d need packages: write.

Doing OIDC login to AWS (instead of using stored AWS keys) → you’d need id-token: write.

👉 In your case (Terraform scans + PR auto-creation):

You need contents: write (to create PRs).

You might need id-token: write if you want to switch from AWS secrets to OIDC.

You don’t need packages: write, unless you plan to push artifacts to GitHub Packages.

Do you want me to show you how to replace AWS secrets with OIDC and id-token: write so your workflow runs without storing AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY?


# brightain's workflow with oidc and terragrunt

name: Deploy-primary-cloudguru-shared-Network(INT)
on:
  push:
    branches:
      - main # Run on push to the main branch
      - "*" # Run on push to any feature branch
    paths:
      - ".github/workflows/deploy-primary-cloudguru-shared.yaml"
      - "Terraform/deployments/CloudG/Shared-account/primary/**/*"
  workflow_dispatch:
    inputs:
      terragrunt_action:
        description: "Select the terragrunt action to perform"
        required: true
        type: choice
        options:
          - "plan"
          - "apply"
          - "destroy"
      skip_nochange:
        description: "Apply even if no change is reported in the plan"
        required: false
        type: boolean

env:
  IAM_ROLE: arn:aws:iam::586794444719:role/cloudguru-OIDCGitHubRole-role
  REGION: us-east-1
  DEPLOYMENT_PATH: Terraform/deployments/CloudG/Shared-account/primary
  TF_VAR_ANSIBLE_TOWER_USERNAME: ${{ secrets.TF_VAR_ANSIBLE_USERNAME }}
  TF_VAR_ANSIBLE_TOWER_PASSWORD: ${{ secrets.TF_VAR_ANSIBLE_PASSWORD }}
  TF_VAR_USER_USERNAME1: ${{ secrets.TF_VAR_USER_USERNAME1 }}
  TF_VAR_USER_PASSWORD1: ${{ secrets.TF_VAR_USER_PASSWORD1 }}
  TF_VAR_USER_USERNAME2: ${{ secrets.TF_VAR_USER_USERNAME2 }}
  TF_VAR_USER_PASSWORD2: ${{ secrets.TF_VAR_USER_PASSWORD2 }}

permissions:
  packages: write
  contents: read
  id-token: write

jobs:
  Plan:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        runner: [ubuntu-latest]
    defaults:
      run:
        shell: bash
        working-directory: ${{ env.DEPLOYMENT_PATH }}
    steps:
      - name: Clone the repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1.7.0
        with:
          role-to-assume: ${{ env.IAM_ROLE }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          aws-region: ${{ env.REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-Terraform@v1
        with:
          terraform_version: 1.11.1
          terraform_wrapper: false

      - name: Verify Terraform version
        run: terraform --version

      - name: Setup Terraform wrapper path
        run: which terraform

      - name: Setup Terragrunt
        run: |
          sudo wget -q -O /bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v0.75.0/terragrunt_linux_amd64"
          sudo chmod +x /bin/terragrunt

      - name: Initialiize Terragrunt
        id: init
        run: terragrunt init

      - name: Plan Terragrunt
        id: plan
        run: terragrunt run-all plan --terragrunt-non-interactive

  Approve:
    needs: Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.terragrunt_action == 'apply' && github.ref == 'refs/heads/main'
    environment: # This is what allows environment secrets to work instead of repository secrets
      name: production
    steps:
      - name: Awaiting approval before applying changes
        run: echo "Waiting for manual approval to apply changes."

  Apply:
    needs: Approve
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.terragrunt_action == 'apply' && github.ref == 'refs/heads/main'
    environment:
      name: production
    env:
      IAM_ROLE: arn:aws:iam::586794444719:role/cloudguru-OIDCGitHubRole-role
      REGION: us-east-1
      DEPLOYMENT_PATH: Terraform/deployments/INT/Shared-account/primary

    defaults:
      run:
        shell: bash
    steps:
      - name: Clone the repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1.7.0
        with:
          role-to-assume: ${{ env.IAM_ROLE }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          aws-region: ${{ env.REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-Terraform@v1
        with:
          terraform_version: 1.11.1
          terraform_wrapper: false

      - name: Verify Terraform version
        run: terraform --version

      - name: Setup Terraform wrapper path
        run: which terraform

      - name: Setup Terragrunt
        run: |
          sudo wget -q -O /bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v0.75.0/terragrunt_linux_amd64"
          sudo chmod +x /bin/terragrunt

      - name: Apply Terragrunt
        working-directory: ${{ env.DEPLOYMENT_PATH }}
        run: terragrunt run-all apply --terragrunt-non-interactive

  Destroy:
    needs: Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.terragrunt_action == 'destroy' && github.ref == 'refs/heads/main'
    env:
      IAM_ROLE: arn:aws:iam::586794444719:role/cloudguru-OIDCGitHubRole-role
      REGION: us-east-1
      DEPLOYMENT_PATH: Terraform/deployments/INT/Shared-account/primary
    steps:
      - name: Clone the repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1.7.0
        with:
          role-to-assume: ${{ env.IAM_ROLE }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          aws-region: ${{ env.REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-Terraform@v1
        with:
          terraform_version: 1.11.1
          terraform_wrapper: false

      - name: Verify Terraform version
        run: terraform --version

      - name: Setup Terraform wrapper path
        run: which terraform

      - name: Setup Terragrunt
        run: |
          sudo wget -q -O /bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v0.75.0/terragrunt_linux_amd64"
          sudo chmod +x /bin/terragrunt

      - name: Destroy Terragrunt
        working-directory: ${{ env.DEPLOYMENT_PATH }}
        run: terragrunt run-all destroy --terragrunt-non-interactive

# mine earlier with access keys
name: Terraform CI/CD

on:
  push:
    branches:
      - "dev"     # feature branch for testing
  pull_request:
    branches:
      - "main"    # PRs target main
  workflow_dispatch:
    inputs:
      terraform_action:
        description: "Select the Terraform action to perform"
        required: true
        type: choice
        options:
          - "plan"
          - "apply"
          - "destroy"
      skip_nochange:
        description: "Apply even if no change is reported in the plan"
        required: false
        type: boolean

permissions:
  contents: write
  pull-requests: write

env:
  TF_VAR_management_account_id: ${{ secrets.AWS_MANAGEMENT_ACCOUNT_ID }}
  TF_VAR_dev_account_id: ${{ secrets.AWS_DEV_ACCOUNT_ID }}
  AWS_REGION: ${{ secrets.AWS_REGION }}
  SONAR_PROJECT_KEY: dainmusty_MULTI-VPC-INTER-REGION-TGW
  SONAR_ORGANIZATION: effulgencetech

jobs:
  tflint:
    name: Run TFLint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
      - name: Run TFLint
        run: tflint

  checkov:
    name: Run Checkov
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Checkov Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          quiet: true
          soft_fail: false

  sonarcloud:
    name: Run SonarCloud Code Quality Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install SonarCloud Scanner
        run: |
          curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
          unzip -q sonar-scanner.zip
          echo "$PWD/sonar-scanner-5.0.1.3006-linux/bin" >> $GITHUB_PATH
      - name: SonarCloud Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
            -Dsonar.organization=${SONAR_ORGANIZATION} \
            -Dsonar.branch.name=${GITHUB_REF_NAME} \
            -Dsonar.sources=. \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.login=$SONAR_TOKEN

  create-pr:
    name: Create Pull Request into Main
    runs-on: ubuntu-latest
    needs: [tflint, checkov, sonarcloud]
    if: github.ref == 'refs/heads/dev'
    steps:
      - uses: actions/checkout@v4
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v6
        with:
          branch: auto-pr/dev-to-main
          base: main
          title: "Auto PR: Merge dev into main"
          body: "This PR was automatically created after passing scans (TFLint, Checkov, SonarCloud)."
          labels: auto-pr

  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    needs: create-pr
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Terraform Plan
        working-directory: env/dev
        run: terraform plan -out=tfplan

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Terraform Apply
        working-directory: env/dev
        run: terraform apply -auto-approve

  terraform-manual:
    name: Manual Terraform Action
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Run Terraform Action
        working-directory: env/dev
        run: |
          if [ "${{ github.event.inputs.terraform_action }}" == "plan" ]; then
            terraform plan
          elif [ "${{ github.event.inputs.terraform_action }}" == "apply" ]; then
            terraform apply -auto-approve
          elif [ "${{ github.event.inputs.terraform_action }}" == "destroy" ]; then
            terraform destroy -auto-approve
          fi

# mine with oidc role
name: Terraform CI/CD

on:
  push:
    branches:
      - "dev"     # feature branch for testing
  pull_request:
    branches:
      - "main"    # PRs target main
  workflow_dispatch:
    inputs:
      terraform_action:
        description: "Select the Terraform action to perform"
        required: true
        type: choice
        options:
          - "plan"
          - "apply"
          - "destroy"
      skip_nochange:
        description: "Apply even if no change is reported in the plan"
        required: false
        type: boolean

permissions:
  contents: write
  pull-requests: write
  id-token: write   # required for OIDC role assumption

env:
  TF_VAR_management_account_id: ${{ secrets.AWS_MANAGEMENT_ACCOUNT_ID }}
  TF_VAR_dev_account_id: ${{ secrets.AWS_DEV_ACCOUNT_ID }}
  AWS_REGION: ${{ secrets.AWS_REGION }}
  SONAR_PROJECT_KEY: dainmusty_MULTI-VPC-INTER-REGION-TGW
  SONAR_ORGANIZATION: effulgencetech

jobs:
  tflint:
    name: Run TFLint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
      - name: Run TFLint
        run: tflint

  checkov:
    name: Run Checkov
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Checkov Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          quiet: true
          soft_fail: false

  sonarcloud:
    name: Run SonarCloud Code Quality Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install SonarCloud Scanner
        run: |
          curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
          unzip -q sonar-scanner.zip
          echo "$PWD/sonar-scanner-5.0.1.3006-linux/bin" >> $GITHUB_PATH
      - name: SonarCloud Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
            -Dsonar.organization=${SONAR_ORGANIZATION} \
            -Dsonar.branch.name=${GITHUB_REF_NAME} \
            -Dsonar.sources=. \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.login=$SONAR_TOKEN

  create-pr:
    name: Create Pull Request into Main
    runs-on: ubuntu-latest
    needs: [tflint, checkov, sonarcloud]
    if: github.ref == 'refs/heads/dev'
    steps:
      - uses: actions/checkout@v4
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v6
        with:
          branch: auto-pr/dev-to-main
          base: main
          title: "Auto PR: Merge dev into main"
          body: "This PR was automatically created after passing scans (TFLint, Checkov, SonarCloud)."
          labels: auto-pr

  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    needs: create-pr
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_IAM_ROLE_ARN }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          aws-region: ${{ env.AWS_REGION }}

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Terraform Plan
        working-directory: env/dev
        run: terraform plan -out=tfplan

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_IAM_ROLE_ARN }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          aws-region: ${{ env.AWS_REGION }}

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Terraform Apply
        working-directory: env/dev
        run: terraform apply -auto-approve

  terraform-manual:
    name: Manual Terraform Action
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_IAM_ROLE_ARN }}
          role-session-name: GitHub_to_AWS_via_FederatedOIDC
          aws-region: ${{ env.AWS_REGION }}

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.8.5

      - name: Terraform Init
        working-directory: env/dev
        run: terraform init -input=false

      - name: Run Terraform Action
        working-directory: env/dev
        run: |
          if [ "${{ github.event.inputs.terraform_action }}" == "plan" ]; then
            terraform plan
          elif [ "${{ github.event.inputs.terraform_action }}" == "apply" ]; then
            terraform apply -auto-approve
          elif [ "${{ github.event.inputs.terraform_action }}" == "destroy" ]; then
            terraform destroy -auto-approve
          fi
