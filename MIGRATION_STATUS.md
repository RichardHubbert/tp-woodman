# Migration to tp-core Architecture - Status

## Current Situation

This repository (tp-woodman) is being converted from the upstream core to a client repository of the new tp-core upstream.

## Completed Steps

1. ✅ Updated `scripts/link-to-core.sh` to point to tp-core
2. ✅ Updated `CLONING.md` to indicate this is a client of tp-core
3. ✅ Updated `UPDATING.md` with tp-core references
4. ✅ Updated `README.md` to show this is a client repository
5. ✅ Added core remote configuration

## Blocked: tp-core Repository Not Found

The repository https://github.com/RichardHubbert/tp-core does not exist yet.

## Next Steps to Complete Migration

### Option 1: Create tp-core from tp-woodman (Recommended)

Since tp-woodman has been serving as the core, create tp-core from its current state:

```bash
# 1. Create a new repository on GitHub: RichardHubbert/tp-core
# 2. Clone tp-woodman to a temporary location
git clone https://github.com/RichardHubbert/tp-woodman.git tp-core-temp
cd tp-core-temp

# 3. Remove client-specific files to create a clean core
# - Replace src/config/site.ts with a template version
# - Remove brand-specific assets from public/brand/
# - Keep the core infrastructure

# 4. Push to tp-core
git remote add core https://github.com/RichardHubbert/tp-core.git
git push core main

# 5. Return to tp-woodman and complete the merge
cd /path/to/tp-woodman
git fetch core main
git merge core/main --allow-unrelated-histories
```

### Option 2: Use Existing Repository as Core

If another repository should be the core (e.g., tablepilotpro), update the scripts to point there instead.

### Option 3: Create Empty tp-core

Start tp-core as a fresh repository and gradually migrate the core functionality.

## When tp-core is Ready

Once tp-core exists, run in this repository (tp-woodman):

```bash
# Fetch from tp-core
git fetch core main

# Merge with unrelated histories
git merge core/main --allow-unrelated-histories \
  -m "Initial merge from tp-core upstream"

# Verify build
npm install
npm run build

# Test the application
npm run dev

# Push changes
git push origin cursor/repoint-to-tp-core-653d
```

## Protected Files

The following files are protected by `.gitattributes` and will not be overwritten during merges:
- `src/config/site.ts` (Woodman and Olive configuration)
- `public/brand/**` (Woodman and Olive brand assets)
- `.env` and `.env.local` (environment configuration)

This ensures Woodman and Olive branding and configuration remain intact when pulling updates from tp-core.
