#   GitHub Repository Setup Instructions

##   Required GitHub Repositories

You need to create **3 repositories** on GitHub:

1. **fluxcd-gitops** (Main repository with all documentation and automation)
2. **sample-app-helm-chart** (Helm chart repository)
3. **flux-app-delivery** (FluxCD delivery repository)

##   Manual Repository Creation

### Step 1: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name like "GitOps Demo Setup"
4. Select scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
5. Click "Generate token"
6. Copy the token (you'll need it for the automation scripts)

### Step 2: Create Repositories

#### Option A: Using GitHub Web Interface

1. Go to https://github.com/new
2. Create each repository:

**Repository 1: fluxcd-gitops**
- Repository name: `fluxcd-gitops`
- Description: `Complete GitOps demo with 100% automation - Infrastructure, FluxCD, and Application deployment`
- Public
- Don't initialize with README (we'll push our own)

**Repository 2: sample-app-helm-chart**
- Repository name: `sample-app-helm-chart`
- Description: `Sample NGINX application Helm chart for GitOps demo`
- Public
- Don't initialize with README

**Repository 3: flux-app-delivery**
- Repository name: `flux-app-delivery`
- Description: `FluxCD application delivery manifests for GitOps demo`
- Public
- Don't initialize with README

#### Option B: Using GitHub CLI

```bash
# Install GitHub CLI if not installed
# macOS: brew install gh
# Ubuntu: sudo apt install gh

# Login to GitHub
gh auth login

# Create repositories
gh repo create fluxcd-gitops --public --description "Complete GitOps demo with 100% automation"
gh repo create sample-app-helm-chart --public --description "Sample NGINX application Helm chart for GitOps demo"
gh repo create flux-app-delivery --public --description "FluxCD application delivery manifests for GitOps demo"
```

##   Push Code to Repositories

### Step 1: Push Main Repository (fluxcd-gitops)

```bash
# In the main fluxcd-gitops directory
cd /Users/paraskanwar/fluxcd-gitops

# Add remote and push
git remote add origin https://github.com/paraskanwarit/fluxcd-gitops.git
git push -u origin main
```

### Step 2: Push Helm Chart Repository

```bash
# Navigate to helm chart directory
cd sample-app-helm-chart

# Initialize git and push
git init
git add .
git commit -m "Initial commit: Sample NGINX Helm chart"
git remote add origin https://github.com/paraskanwarit/sample-app-helm-chart.git
git push -u origin main
```

### Step 3: Push FluxCD Delivery Repository

```bash
# Navigate to delivery directory
cd ../flux-app-delivery

# Initialize git and push
git init
git add .
git commit -m "Initial commit: FluxCD delivery manifests"
git remote add origin https://github.com/paraskanwarit/flux-app-delivery.git
git push -u origin main
```

## 🤖 Automated Setup (Alternative)

If you have a GitHub Personal Access Token, you can use the automation script:

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_github_token_here"

# Run the automation script
./scripts/setup-github-repos.sh
```

##   Repository Structure

### fluxcd-gitops (Main Repository)
```
fluxcd-gitops/
├── README.md                    # Complete documentation
├── DEMO_SCRIPT.md              # Professional demo script
├── AUTOMATION_SUMMARY.md       # Automation overview
├── QUICK_REFERENCE.md          # Quick reference guide
├── scripts/
│   ├── complete-setup.sh       # Full automation script
│   └── setup-github-repos.sh   # GitHub repo automation
├── gke-gitops-infra/           # Infrastructure code
├── sample-app-helm-chart/      # Helm chart (copy)
└── flux-app-delivery/          # FluxCD manifests (copy)
```

### sample-app-helm-chart (Helm Chart Repository)
```
sample-app-helm-chart/
├── charts/
│   └── sample-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── README.md
└── diagram-helm.md
```

### flux-app-delivery (FluxCD Repository)
```
flux-app-delivery/
├── namespaces/
│   └── sample-app-namespace.yaml
├── helmrelease/
│   ├── sample-app-helmrepository.yaml
│   └── sample-app-helmrelease.yaml
├── kustomization.yaml
├── README.md
└── diagram-delivery.md
```

##   Verification

After pushing all repositories, verify they're accessible:

1. **Main Repository**: https://github.com/paraskanwarit/fluxcd-gitops
2. **Helm Chart**: https://github.com/paraskanwarit/sample-app-helm-chart
3. **Delivery**: https://github.com/paraskanwarit/flux-app-delivery

##   Next Steps

Once all repositories are pushed:

1. **Test the automation**: Run `./scripts/complete-setup.sh`
2. **Run the demo**: Follow `DEMO_SCRIPT.md`
3. **Share the repositories**: Use them for demos and presentations

##   Troubleshooting

### Repository Already Exists
If a repository already exists, you can:
```bash
# Force push (be careful!)
git push --force origin main

# Or delete and recreate the repository
```

### Authentication Issues
```bash
# Use GitHub CLI for authentication
gh auth login

# Or use personal access token
git remote set-url origin https://YOUR_TOKEN@github.com/paraskanwarit/REPO_NAME.git
```

---

**  Once all repositories are pushed, your GitOps demo will be fully accessible and ready for presentations!** 