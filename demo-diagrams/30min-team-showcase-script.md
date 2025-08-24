# 30-Minute GitOps Team Showcase Script

*A practical, conversational demo for developers with 1-4 years experience*

---

## Opening (2 minutes)

**[Start with energy, casual tone]**

"Hey everyone! So today I want to show you something that's honestly changed how I think about deployments. I've been working with FluxCD and GitOps for about 2 years now, and I remember when I first heard about it, I was like... 'Wait, so I never have to run kubectl apply again?' 

*[Laugh]* 

And yeah, that's basically it. But it's so much more than that. Let me show you what I've built here and how it actually works in practice."

**DEMO ACTION: Share screen and show repositories**
1. Open browser
2. Navigate to: https://github.com/paraskanwarit
3. Point to these three repositories:
   - fluxcd-gitops
   - sample-app-helm-chart  
   - flux-app-delivery

"So I've got three repositories here, and I know what you're thinking - 'Why three repos? That seems like overkill.' But trust me, there's a method to this madness, and by the end of this demo, you'll see why this separation actually makes our lives easier."

---

## The Big Picture (5 minutes)

**DEMO ACTION: Navigate to main documentation**
1. Click on "fluxcd-gitops" repository
2. Scroll down to show the README
3. Point to the three-repository architecture diagram

"Alright, let me start with the big picture. Look at this diagram here..."

"So here's what we have:

1. **fluxcd-gitops** - This is like our 'setup and infrastructure' repo. Think of it as the foundation.
2. **sample-app-helm-chart** - This is where our actual application lives. Just a simple NGINX app for this demo.
3. **flux-app-delivery** - This is the magic sauce. This tells FluxCD what to deploy and where.

Now, why split it up like this? Well, imagine you're working on a team:
- The platform team manages the infrastructure setup
- The dev team works on the application 
- The DevOps team manages the deployment configurations

Nobody steps on each other's toes, and everyone owns their piece."

**DEMO ACTION: Show workflow diagram**
1. Click on "demo-diagrams" folder
2. Click on "gitops-workflow.md"
3. Point to the sequence diagram

"But here's the cool part - watch this flow. When I make a change to my app, I just push to Git. That's it. FluxCD is sitting there like a watchdog, checking every minute: 'Hey, did anything change?' And when it sees a change, it automatically applies it to the cluster."

*[Pause for effect]*

"No kubectl. No manual deployments. No 'it works on my machine' problems. Just Git push, and boom - deployed."

---

## Live Setup Demo (8 minutes)

**DEMO ACTION: Open terminal**
1. Open terminal application
2. Navigate to project directory:
   ```bash
   cd /Users/paraskanwar/paras-flux-cd-showcase/fluxcd-gitops/scripts
   ```

"Okay, enough talking. Let me show you this thing in action. I'm going to set up this entire GitOps pipeline from scratch, and I want you to time me."

*[Look at audience]*

"Seriously, someone start a timer. I'm claiming this takes 5 minutes."

**DEMO ACTION: Show the setup script**
```bash
# Show what the script does
head -20 complete-setup.sh
```

"So this script does everything:
- Checks if I have all the tools I need
- Connects to my existing GKE cluster
- Installs FluxCD if it's not already there
- Sets up the GitHub repositories
- Configures the GitOps pipeline

Watch this..."

**DEMO ACTION: Run the setup**
```bash
./complete-setup.sh
```

**[While script runs, narrate what's happening]**

"See that? It's checking my prerequisites... connecting to my cluster... 

Oh look, FluxCD is already installed from when I tested this earlier. That's fine, it's smart enough to skip that step.

Now it's setting up the GitHub repositories... configuring the GitOps resources...

And... there we go! Look at that output. The whole pipeline is running."

*[Show the success message]*

"How long was that? Under 5 minutes, right? That's the power of automation."

---

## Show What Just Happened (5 minutes)

**DEMO ACTION: Open new terminal tab**
```bash
# Press Cmd+T to open new tab
```

"Alright, so what actually just happened? Let me show you what's running in my cluster now."

**DEMO ACTION: Check FluxCD controllers**
```bash
kubectl get deployment -n flux-system
```

"So these are the FluxCD controllers. Think of them as little robots that are constantly watching my Git repositories and making sure my cluster matches what's in Git."

**DEMO ACTION: Show GitOps resources**
```bash
kubectl get gitrepository -A
kubectl get helmrelease -A
```

"See these? This is FluxCD saying:
- 'I'm watching these two GitHub repositories'
- 'I'm managing this Helm release called sample-app2'

And look at this..."

**DEMO ACTION: Show the actual application**
```bash
kubectl get pods -n sample-app
kubectl get svc -n sample-app
```

"There's my NGINX application, running with 2 replicas, just like I defined in my Helm chart. FluxCD deployed this automatically just by reading my Git repositories."

**DEMO ACTION: Go back to browser**
1. Switch back to browser
2. Show all three repositories are there with content

"And if I go to GitHub, you can see all three repositories are there, with all the configurations that make this work."

---

## The Magic Moment - Live Change Demo (8 minutes)

*[This is the showstopper moment]*

"Okay, here's where it gets really cool. I'm going to make a change to my application, and you're going to watch it automatically deploy. No kubectl, no manual steps."

**DEMO ACTION: Navigate to Helm chart repository**
1. In browser, go to: https://github.com/paraskanwarit/sample-app-helm-chart
2. Click on "charts" folder
3. Click on "sample-app" folder
4. Click on "values.yaml" file

"So I'm in my Helm chart repository. Let me edit the values.yaml file..."

**DEMO ACTION: Edit the file in GitHub**
1. Click the pencil icon (Edit this file)
2. Find this line:
   ```yaml
   replicaCount: 2
   ```
3. Change it to:
   ```yaml
   replicaCount: 4
   ```

"I'm scaling my app from 2 replicas to 4. Now watch this - I'm just going to commit this change..."

**DEMO ACTION: Commit the change**
1. Scroll down to "Commit changes" section
2. In commit message box, type: "Scale to 4 replicas for demo"
3. Leave description empty
4. Select "Commit directly to the main branch"
5. Click "Commit changes" button

"Done. I just pushed to Git. Now, FluxCD checks for changes every minute, so let's watch what happens..."

**DEMO ACTION: Watch pods in terminal**
```bash
# In terminal, start watching
watch kubectl get pods -n sample-app
```

*[While waiting, explain what's happening]*

"So right now, FluxCD is doing its regular check. It's going to see that my Helm chart changed, download the new version, and apply it to the cluster.

The cool thing is, I don't have to do anything. I don't even have to be logged into the cluster. I could be on vacation, push a change from my phone, and it would still deploy."

*[When pods start changing]*

"There we go! Look at that! You can see new pods spinning up. It's doing a rolling update - keeping the old pods running until the new ones are ready."

*[Wait for all 4 pods to be running]*

"And... done! We now have 4 replicas instead of 2. That's GitOps in action."

**DEMO ACTION: Stop the watch command**
```bash
# Press Ctrl+C to stop watch
```

---

## Show the Rollback Magic (3 minutes)

*[Still in the same terminal]*

"But wait, there's more. What if I made a mistake? What if that change broke something? Watch this..."

**DEMO ACTION: Go back to GitHub commit history**
1. Switch to browser
2. In the sample-app-helm-chart repository, click on "commits" (should show "X commits")
3. Find the commit "Scale to 4 replicas for demo"

"I'm going to revert that commit. In Git, this is just a simple revert..."

**DEMO ACTION: Revert the commit**
1. Click on the commit "Scale to 4 replicas for demo"
2. Click the "Revert" button (top right of the commit view)
3. In the revert dialog, click "Revert this commit"
4. This opens a new commit page
5. The commit message should be auto-filled like "Revert 'Scale to 4 replicas for demo'"
6. Click "Commit changes"

"And now let's watch the cluster..."

**DEMO ACTION: Watch pods again**
```bash
watch kubectl get pods -n sample-app
```

"See that? It's automatically scaling back down to 2 replicas. I didn't run any kubectl commands. I didn't even touch the cluster. I just reverted a Git commit, and the cluster automatically rolled back."

*[When back to 2 pods]*

"That's the power of GitOps. Your Git history becomes your deployment history. Want to rollback? Just revert the commit. Want to see what changed? Look at the Git diff. Everything is auditable, everything is reversible."

**DEMO ACTION: Stop watch**
```bash
# Press Ctrl+C
```

---

## Why This Matters (4 minutes)

*[Stop the watch command, face the audience]*

"Okay, so why am I so excited about this? Let me tell you what this solves:

**Security**: Nobody needs kubectl access to production. Developers push to Git, that's it. The cluster credentials stay with the platform team.

**Consistency**: No more 'it works on my machine.' What's in Git is what's deployed. Period.

**Audit Trail**: Every change is tracked in Git. Your manager asks 'who deployed what when?' Just check the Git history.

**Collaboration**: Multiple people can work on deployments through pull requests. Code review for infrastructure changes.

**Disaster Recovery**: Your entire application state is in Git. Cluster dies? Spin up a new one, point FluxCD at your repos, and you're back."

**DEMO ACTION: Show documentation**
1. Switch to browser
2. Go back to fluxcd-gitops repository
3. Show the README

"And look, I've documented everything here. The architecture, the setup process, troubleshooting guides. This isn't just a demo - this is a production-ready pattern you can use tomorrow."

**DEMO ACTION: Show troubleshooting section**
1. Scroll down to the troubleshooting section in README

"I even included common issues and how to fix them, because let's be honest, things break, and when they do at 2 AM, you want good documentation."

---

## Wrap Up & Next Steps (5 minutes)

*[Close terminal, face audience]*

"So that's GitOps with FluxCD. In 30 minutes, we've:
- Set up a complete GitOps pipeline
- Made a live change and watched it deploy automatically  
- Rolled it back with a Git revert
- Seen how this solves real problems we face every day

Now, I know some of you are thinking 'This looks complicated.' And yeah, there's a learning curve. But think about it - once this is set up, deployments become as simple as a Git push. No more deployment scripts, no more manual kubectl commands, no more 'did I deploy to the right environment?'"

**DEMO ACTION: Show all repositories one final time**
1. Open new browser tabs for:
   - https://github.com/paraskanwarit/fluxcd-gitops
   - https://github.com/paraskanwarit/sample-app-helm-chart
   - https://github.com/paraskanwarit/flux-app-delivery

"Everything I showed you today is in these three repositories. The setup script, the documentation, the examples - it's all there. You can literally run that setup script on your own cluster and have this working in 5 minutes."

*[Pause]*

"Questions? And please, don't ask me to explain Kubernetes RBAC because that's a whole other 30-minute talk."

*[Laugh, wait for questions]*

---

## Anticipated Questions & Answers

### "What if GitHub is down?"
"Great question! FluxCD caches everything locally, so your cluster keeps running. You just can't make new deployments until GitHub is back. But honestly, if GitHub is down, you probably have bigger problems."

### "How do you handle secrets?"
"FluxCD integrates with tools like Sealed Secrets or External Secrets Operator. You encrypt secrets in Git, and they get decrypted in the cluster. Never store plain text secrets in Git."

### "What about different environments?"
"You can have different branches or different repositories for different environments. FluxCD can watch different branches for dev, staging, and prod."

### "Is this overkill for small projects?"
"Maybe. But honestly, once you get used to this workflow, it's hard to go back. Even for small projects, the audit trail and rollback capabilities are worth it."

### "What if FluxCD breaks?"
"FluxCD is pretty stable, but if it breaks, your applications keep running. You just lose the automatic deployment capability until you fix FluxCD. And since everything is in Git, you can always fall back to manual kubectl if needed."

---

## Demo Checklist

**Before the demo:**
- [ ] Test the complete-setup.sh script works
- [ ] Ensure you have a clean GKE cluster running
- [ ] Verify GitHub repositories are accessible
- [ ] Have terminal and browser ready
- [ ] Test the scaling demo (2->4->2 replicas) beforehand
- [ ] Make sure you can access all three GitHub repositories
- [ ] Verify kubectl is connected to the right cluster

**During the demo:**
- [ ] Keep energy high and conversational
- [ ] Explain what you're doing as you do it
- [ ] Don't panic if something doesn't work - troubleshoot live
- [ ] Engage the audience with questions and timing challenges
- [ ] Use humor to keep it light
- [ ] Show actual commands and file changes, not just talk about them

**Terminal commands you'll need:**
```bash
# Navigate to scripts
cd /Users/paraskanwar/paras-flux-cd-showcase/fluxcd-gitops/scripts

# Run setup
./complete-setup.sh

# Check FluxCD
kubectl get deployment -n flux-system

# Check GitOps resources
kubectl get gitrepository -A
kubectl get helmrelease -A

# Check application
kubectl get pods -n sample-app
kubectl get svc -n sample-app

# Watch pods during changes
watch kubectl get pods -n sample-app
```

**GitHub actions you'll need:**
1. Navigate to sample-app-helm-chart repository
2. Edit charts/sample-app/values.yaml
3. Change replicaCount: 2 to replicaCount: 4
4. Commit with message "Scale to 4 replicas for demo"
5. Later: find the commit and click "Revert"
6. Commit the revert

**After the demo:**
- [ ] Share the repository links in chat
- [ ] Offer to help with individual setup questions
- [ ] Schedule follow-up sessions if there's interest
- [ ] Document any issues that came up for next time

---

**Remember**: You're not just showing a tool, you're showing a better way to work. Make it personal, make it practical, and make it something they want to try themselves. The key is showing real commands and real file changes, not just talking about concepts.