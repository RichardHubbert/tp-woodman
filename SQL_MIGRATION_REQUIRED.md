# 🚨 CRITICAL: SQL Migration Required

## Database Migration to Run

After merging this PR, you **MUST** run this SQL migration in Supabase to apply the security fixes.

**IMPORTANT**: This is a combined security migration that covers multiple security fixes across all TablePilot sites. It should be run **ONCE** on the shared Supabase project.

### Method 1: Supabase CLI (Recommended)

```bash
# From the project root
supabase db push
```

This will automatically apply the migration file: `supabase/migrations/20261019000000_tighten_security_rls.sql`

---

### Method 2: Manual SQL Execution

If you don't have the Supabase CLI installed, run this SQL manually in Supabase Dashboard:

**Navigation**: Supabase Dashboard → SQL Editor → New Query

**Copy and paste the entire contents of this file**: `supabase/migrations/20261019000000_tighten_security_rls.sql`

This combined migration file:
- Replaces overly permissive RLS policies
- Creates the `tp_is_admin()` RPC function for admin checks
- Creates the `get_booking_availability()` RPC function for public availability queries
- Protects profile privileges with a trigger
- Secures storage bucket policies
- Makes Richard Hubbert (richardhubbert@gmail.com) an admin automatically
- Is idempotent (safe to run multiple times)

---

## What This Migration Does

### Core Security Improvements

1. **Admin Helper Function**: Creates `tp_is_admin()` RPC that safely checks if the current user has admin role
2. **Public Availability Function**: Creates `get_booking_availability(p_date, p_restaurant_id)` RPC that returns booking slots without exposing customer details (names, emails, phones)
3. **Profile Protection**: Adds trigger to prevent users from making themselves admin
4. **Drops ALL Existing Policies**: Removes all old, potentially insecure policies and replaces with known-good set

### New RLS Policy Set

**Bookings**:
- ❌ **Before**: Anyone could view all bookings (including customer emails, phones)
- ✅ **After**: Public can INSERT bookings; only admins can view/update/delete
- ✅ Availability checks use `get_booking_availability()` RPC (no customer data exposed)

**Restaurants**:
- ✅ Public can view active restaurants
- ✅ Only admins can manage all restaurants

**Tables**:
- ✅ Public can view tables (needed for availability checks)
- ✅ Only admins can manage tables

**Profiles**:
- ✅ Users can view/edit their own profile
- ✅ Only admins can view all profiles and change roles
- ✅ Trigger prevents users from making themselves admin

**Businesses & Customers**:
- ✅ Admin-only access

**Storage (restaurants bucket)**:
- ✅ Anyone can view images
- ✅ Only admins can upload/update/delete images

---

## Code Changes Already Applied

The following code changes have been made to work with the new RLS policies:

1. **`fetchBookingsForDate`**: Now uses `supabase.rpc('get_booking_availability')` instead of direct SELECT
2. **`createBooking`**: Generates ID with `crypto.randomUUID()`, inserts without `.select()`, builds returned booking locally
3. **Admin checks**: Use `tp_is_admin()` RPC instead of direct profile queries
4. **No hard-coded IDs**: Uses config business IDs instead of hard-coded values

---

## Grant Admin Access to Users

The migration automatically makes richardhubbert@gmail.com an admin. To grant admin access to other users:

```sql
-- Replace 'admin@example.com' with the actual admin user's email
UPDATE profiles 
SET role = 'admin' 
WHERE user_id = (
  SELECT id FROM auth.users WHERE email = 'admin@example.com'
);
```

Repeat this for each user who should have admin access.

---

## Verify Migration Success

After running the migration, verify it worked:

```sql
-- Check that the RPC functions exist
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('tp_is_admin', 'get_booking_availability');

-- Check that policies were created
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
  AND policyname LIKE 'tp_%'
ORDER BY tablename, policyname;

-- Check admin users
SELECT u.email, p.role
FROM auth.users u
JOIN profiles p ON p.user_id = u.id
WHERE p.role = 'admin';
```

---

## Testing After Migration

### Test 1: Admin Access Works
Log in as admin user and access `/admin` - should work

### Test 2: Non-Admin Access Blocked
Log in as non-admin user and try `/admin` - should see "Access Denied"

### Test 3: Customer Bookings Still Work
As anonymous user (not logged in), create a booking - should work without errors

### Test 4: Availability Check Works
On booking page, select a date - available time slots should appear

---

## Rollback (Emergency Only)

If you need to rollback these security changes (NOT RECOMMENDED):

This migration is idempotent - you can run it again to restore the secure state. There is no partial rollback; contact support if you need to revert.

---

## Support

If you encounter issues:
1. Check Supabase logs: Dashboard → Logs → Database
2. Verify migration completed without errors
3. Check browser console for RPC call errors
4. Refer to `SECURITY_SETUP.md` for detailed troubleshooting
