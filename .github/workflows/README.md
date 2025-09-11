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

# put this in sonar-project.properties to ing
# 
