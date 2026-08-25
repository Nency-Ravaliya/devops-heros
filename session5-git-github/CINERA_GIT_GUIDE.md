# 🍿 CINERA (Netflix Clone) - Complete Git & GitHub Mastery Guide & Notes

Welcome to the **Complete Git & GitHub Workflow Guide** built around a real-world production application: **CINERA** (a full-stack Netflix clone).

This guide walks you through every core Git command, branching strategy, conflict resolution technique, and GitHub collaboration pattern taught in DevOps Session 5, using **CINERA** as our hands-on example.

---

## 📂 1. CINERA Repository Structure & Initialization

Imagine starting work on the CINERA project codebase:

```text
cinera/
├── .gitignore              # Files to ignore in Git tracking
├── README.md               # Project documentation
├── client/                 # React frontend
└── server/                 # Node.js Express backend
```

### A. Initializing the Repository

* **Initialize a new Git repository**:
  ```bash
  cd cinera
  git init
  ```

* **Configure Git User Identity (Global or Project-Level)**:
  ```bash
  git config --global user.name "Durga Prasad"
  git config --global user.email "durga@example.com"
  ```

* **Create `.gitignore` file**:
  Ensure sensitive or auto-generated files aren't tracked:
  ```text
  node_modules/
  .env
  dist/
  build/
  *.log
  .DS_Store
  ```

---

## 🛠️ 2. Core Git Workflow Commands (Stage, Commit & Push)

### A. Working Directory $\rightarrow$ Staging Area $\rightarrow$ Repository

```text
+----------------------+      git add .     +--------------------+     git commit -m "..."    +--------------------+
|  Working Directory   |  ----------------> |   Staging Area     |  ----------------------->  |   Local Repository |
| (Modifying CINERA)   |                    | (Index / Prepared) |                            |    (.git folder)   |
+----------------------+                    +--------------------+                            +--------------------+
```

* **Check current repository status**:
  ```bash
  git status
  ```

* **Stage specific files (e.g., Auth component)**:
  ```bash
  git add client/src/components/Auth.jsx
  ```

* **Stage all modified & new files**:
  ```bash
  git add .
  ```

* **Commit staged changes with a descriptive message**:
  ```bash
  git commit -m "feat(auth): add JWT login and signup form for CINERA users"
  ```

* **View commit log history**:
  ```bash
  git log --oneline --graph --decorate
  ```

---

### B. Connecting & Pushing to GitHub Remote

* **Link local repository to GitHub**:
  ```bash
  git remote add origin https://github.com/Durgaprasad-Developer/cinera.git
  ```

* **Verify remote connections**:
  ```bash
  git remote -v
  ```

* **Rename default branch to `main` (if needed)**:
  ```bash
  git branch -M main
  ```

* **Push initial commit to GitHub (and set upstream tracking)**:
  ```bash
  git push -u origin main
  ```

---

## 🌿 3. Branching Strategy for CINERA Feature Development

Never work directly on the `main` branch when building production features. Use feature branches!

```text
main           -------------------------------------> [Production Ready]
                  \                            /
feature/player     \---> [Add Video Player] --/ (Merge via PR)
```

### A. Creating & Switching Branches

* **List all local branches**:
  ```bash
  git branch
  ```

* **Create a new branch for Netflix Video Player feature**:
  ```bash
  git branch feature/video-player
  ```

* **Switch to the new branch**:
  ```bash
  git checkout feature/video-player
  # OR (Modern Git Syntax)
  git switch feature/video-player
  ```

* **Create AND switch to a new branch in one command**:
  ```bash
  git checkout -b feature/user-profile
  # OR
  git switch -c feature/user-profile
  ```

---

### B. Developing a Feature & Pushing to Remote

1. Make changes to CINERA (e.g., adding play/pause controls in `client/src/components/Player.jsx`).
2. Stage and commit:
   ```bash
   git add .
   git commit -m "feat(player): implement custom video controls and HLS streaming"
   ```
3. Push the feature branch to GitHub:
   ```bash
   git push -u origin feature/video-player
   ```

---

## 🔀 4. Merging & Conflict Resolution

### A. Merging Feature into Main Locally

1. Switch back to `main`:
   ```bash
   git switch main
   ```
2. Pull latest changes from remote `main`:
   ```bash
   git pull origin main
   ```
3. Merge your feature branch into `main`:
   ```bash
   git merge feature/video-player
   ```
4. Delete local feature branch after merging:
   ```bash
   git branch -d feature/video-player
   ```

---

### B. Resolving Merge Conflicts

Imagine two developers modified `server/src/server.js` on different branches:

```text
<<<<<<< HEAD (Current Changes in main)
app.listen(5000, () => console.log('CINERA API running on port 5000'));
=======
app.listen(8080, () => console.log('CINERA Server started on port 8080'));
>>>>>>> feature/port-change (Incoming Changes)
```

**Step-by-step Conflict Resolution**:
1. Open the file (`server/src/server.js`) in your code editor.
2. Decide which code to keep (or combine both), and remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
3. Stage the resolved file:
   ```bash
   git add server/src/server.js
   ```
4. Complete the merge commit:
   ```bash
   git commit -m "fix(merge): resolve port conflict in server.js"
   ```

---

## ⚡ 5. Advanced Git Operations for CINERA Engineers

### A. Stashing Work-in-Progress (WIP)
Suppose you are in the middle of editing `client/src/App.jsx` and your manager asks you to urgently fix a critical bug in `main`.

* **Stash uncommitted changes**:
  ```bash
  git stash save "WIP: custom video seek bar"
  ```
* **List all stashes**:
  ```bash
  git stash list
  ```
* **Apply and restore stashed work**:
  ```bash
  git stash pop
  ```

---

### B. Undoing & Reverting Changes

* **Discard local uncommitted modifications in a file**:
  ```bash
  git restore client/src/components/Header.jsx
  ```

* **Unstage a file (keep local edits)**:
  ```bash
  git restore --staged package.json
  ```

* **Safely undo a published commit (creates a new inverse commit)**:
  ```bash
  git revert <commit-hash>
  ```

* **Reset local branch to a previous commit (Danger Zone)**:
  ```bash
  # Soft reset: Keeps file changes staged
  git reset --soft HEAD~1

  # Hard reset: Discards all uncommitted changes completely
  git reset --hard HEAD~1
  ```

---

### C. Rebasing vs. Merging
Rebasing re-applies your feature branch commits on top of the latest `main` branch commit to keep a clean, linear git history.

```bash
git switch feature/video-player
git rebase main
```

---

### D. Cherry-Picking
Copy a specific commit from another branch into your current branch:
```bash
git cherry-pick <commit-hash>
```

---

## 👥 6. GitHub Team Collaboration Workflow (Fork & Upstream)

When collaborating on team projects like `upsteam` repository:

1. **Fork** the original team repository (`Nency-Ravaliya/cinera`) on GitHub to your account (`Durgaprasad-Developer/cinera`).
2. **Clone** your fork to your computer:
   ```bash
   git clone https://github.com/Durgaprasad-Developer/cinera.git
   ```
3. **Add Upstream Remote** to sync with main repo updates:
   ```bash
   git remote add upstream https://github.com/Nency-Ravaliya/cinera.git
   ```
4. **Fetch & Sync Upstream Updates**:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```
5. Create feature branch $\rightarrow$ Commit changes $\rightarrow$ Push to `origin` $\rightarrow$ Open **Pull Request (PR)** on GitHub!

---

## 📋 Quick Cheat Sheet Summary

| Action | Command |
| :--- | :--- |
| **Check Status** | `git status` |
| **Stage Changes** | `git add .` |
| **Commit Changes** | `git commit -m "description"` |
| **Create & Switch Branch** | `git checkout -b feature-name` |
| **Pull Upstream Updates** | `git pull upstream main` |
| **Push Branch** | `git push -u origin feature-name` |
| **View History** | `git log --oneline --graph` |
| **Stash Changes** | `git stash` / `git stash pop` |
