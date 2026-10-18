# Repoint to tp-core - Completion Summary

## 🎯 Task Status: Partially Complete (Blocked)

The task to repoint tp-woodman to tp-core as the upstream has been **mostly completed**, but is **blocked** by the tp-core repository not existing yet.

## ✅ What Was Completed

### 1. Scripts Updated
- ✅ `scripts/link-to-core.sh` - Now points to tp-core
- ✅ `scripts/update-from-core.sh` - Already compatible (works with any remote named 'core')

### 2. Documentation Updated
- ✅ `README.md` - Updated to indicate this is a client of tp-core
- ✅ `CLONING.md` - Added tp-core upstream references
- ✅ `UPDATING.md` - Changed all tp-woodman references to tp-core

### 3. Git Configuration
- ✅ Added 'core' remote pointing to tp-core
- ✅ Configured merge driver (`merge.ours.driver = true`)
- ✅ Verified `.gitattributes` protects client-specific files

### 4. Build & Branding Verification
- ✅ Build passes (`npm run build` successful)
- ✅ Woodman and Olive configuration intact in `src/config/site.ts`
- ✅ Brand assets preserved in `public/brand/`
- ✅ index.html shows correct Woodman and Olive branding

### 5. Pull Request
- ✅ Created PR #3: https://github.com/RichardHubbert/tp-woodman/pull/3
- ✅ Branch: cursor/repoint-to-tp-core-653d
- ✅ Status: Draft (awaiting tp-core)

## ❌ What Could Not Be Completed

### Blocked: Initial Merge from tp-core

The task requested "do the first merge from tp-core main (--allow-unrelated-histories)" but this cannot be done because:

**The tp-core repository does not exist at: https://github.com/RichardHubbert/tp-core**

Verified multiple times:
- GitHub API confirms: 404 Not Found
- git fetch fails: "Repository not found"
- gh CLI confirms: Repository does not exist

## 🔧 How to Complete

### Step 1: Create tp-core Repository

You need to create https://github.com/RichardHubbert/tp-core

**Recommended approach:**
```bash
# 1. Create new repo on GitHub: RichardHubbert/tp-core
# 2. Clone tp-woodman to create the core
git clone https://github.com/RichardHubbert/tp-woodman.git tp-core-temp
cd tp-core-temp

# 3. Make it a generic core (optional but recommended)
# - Replace src/config/site.ts with a template/example
# - Remove Woodman & Olive brand assets
# - Keep all infrastructure code

# 4. Push to tp-core
git remote add core https://github.com/RichardHubbert/tp-core.git
git push core main
```

### Step 2: Complete the Merge in tp-woodman

Once tp-core exists:

```bash
cd tp-woodman
git checkout cursor/repoint-to-tp-core-653d

# Fetch from tp-core
git fetch core main

# Merge with unrelated histories
git merge core/main --allow-unrelated-histories \
  -m "Initial merge from tp-core upstream"

# Protected files (site.ts, brand assets) will NOT be overwritten
# thanks to .gitattributes merge=ours configuration

# Verify
npm install
npm run build

# Push
git push origin cursor/repoint-to-tp-core-653d
```

### Step 3: Merge the PR

Once the merge is complete, mark PR #3 as ready for review and merge it.

## 🔒 Protected Configuration

These files are protected and will NOT be overwritten during the merge:
- `src/config/site.ts` - Woodman and Olive configuration
- `public/brand/**` - Woodman and Olive brand assets
- `.env`, `.env.local` - Environment variables

## 📊 Current State

**Branch:** cursor/repoint-to-tp-core-653d
**Status:** Ready for merge from tp-core (once repo exists)
**Build:** ✅ Passing
**Branding:** ✅ Intact
**PR:** https://github.com/RichardHubbert/tp-woodman/pull/3 (Draft)

## 💡 Alternative: Use Different Repository as Core

If tp-core should actually be a different repository (e.g., if it's named differently or is a private repo), update these files:

1. `scripts/link-to-core.sh` - Change CORE_REPO_URL
2. Git remote: `git remote set-url core <new-url>`

Then retry the fetch and merge.
