# 🚨 CRITICAL: SQL Migration Required

## Database Migration to Run

After merging this PR, you **MUST** run this SQL migration in Supabase to apply the security fixes.

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

Or run this SQL directly:

```sql
-- ============================================
-- Security Fix: Tighten Row Level Security policies
-- ============================================

-- 1. Drop existing overly permissive booking policies
DROP POLICY IF EXISTS "Bookings are viewable by everyone" ON bookings;
DROP POLICY IF EXISTS "Bookings are viewable by business admin" ON bookings;
DROP POLICY IF EXISTS "Authenticated users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Bookings are manageable by admin" ON bookings;

-- 2. Create strict booking policies
CREATE POLICY "Anonymous users can create bookings" ON bookings
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Admin users can view all bookings" ON bookings
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can update bookings" ON bookings
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can delete bookings" ON bookings
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 3. Tighten restaurant policies
DROP POLICY IF EXISTS "Restaurants are viewable by everyone" ON restaurants;
DROP POLICY IF EXISTS "Restaurants are manageable by admin" ON restaurants;

CREATE POLICY "Public can view active restaurants" ON restaurants
  FOR SELECT TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "Admin users can manage restaurants" ON restaurants
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 4. Secure tables
ALTER TABLE IF EXISTS tables ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tables are viewable by everyone" ON tables;
DROP POLICY IF EXISTS "Tables are manageable by admin" ON tables;

CREATE POLICY "Public can view tables" ON tables
  FOR SELECT TO anon, authenticated
  USING (true);

CREATE POLICY "Admin users can manage tables" ON tables
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 5. Secure profiles
DROP POLICY IF EXISTS "Profiles are viewable by owner" ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by business admin" ON profiles;

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admin users can view all profiles" ON profiles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage profiles" ON profiles
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.role = 'admin'
    )
  );

-- 6. Secure businesses
DROP POLICY IF EXISTS "Businesses are viewable by authenticated users" ON businesses;
DROP POLICY IF EXISTS "Businesses are manageable by admin" ON businesses;
DROP POLICY IF EXISTS "Businesses are manageable by business admin" ON businesses;

CREATE POLICY "Admin users can view businesses" ON businesses
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage businesses" ON businesses
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 7. Secure customers
DROP POLICY IF EXISTS "Customers are viewable by business admin" ON customers;
DROP POLICY IF EXISTS "Customers are manageable by business admin" ON customers;

CREATE POLICY "Admin users can view customers" ON customers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage customers" ON customers
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

---

## Grant Admin Access to Users

After running the migration, grant admin access to authorized users:

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
-- Check that policies were created
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('bookings', 'restaurants', 'tables', 'profiles', 'businesses', 'customers')
ORDER BY tablename, policyname;

-- You should see policies like:
-- - "Anonymous users can create bookings"
-- - "Admin users can view all bookings"
-- - "Public can view active restaurants"
-- etc.
```

---

## What This Migration Does

### Bookings Table
- ❌ **Before**: Anyone could view all bookings (including guest emails, phone numbers)
- ✅ **After**: Only users with `role = 'admin'` can view bookings
- ✅ Anonymous users can still INSERT bookings (for customer booking form)

### Restaurants Table
- ❌ **Before**: Policies were inconsistent
- ✅ **After**: Anonymous users can view active restaurants (public info)
- ✅ Only admins can create/update/delete restaurants

### Tables, Profiles, Businesses, Customers
- ❌ **Before**: Overly permissive or missing policies
- ✅ **After**: Only admin users can manage these resources
- ✅ Tables remain publicly viewable (needed for availability checks)

---

## Testing After Migration

### Test 1: Admin Access Works
```sql
-- As an admin user, you should be able to query bookings
SELECT * FROM bookings LIMIT 5;
```

### Test 2: Non-Admin Access Blocked
Log in as a non-admin user and try:
```sql
-- This should fail with "permission denied"
SELECT * FROM bookings LIMIT 5;
```

### Test 3: Customer Bookings Still Work
As an anonymous user (not logged in), the booking form should still work on the website.

---

## Rollback (Emergency Only)

If you need to rollback these security changes (NOT RECOMMENDED):

```sql
-- WARNING: This restores the security vulnerability!
DROP POLICY IF EXISTS "Anonymous users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Admin users can view all bookings" ON bookings;

CREATE POLICY "Bookings are viewable by everyone" ON bookings
  FOR SELECT USING (true);
```

---

## Support

If you encounter issues:
1. Check Supabase logs: Dashboard → Logs → Database
2. Verify user has `role = 'admin'` in profiles table
3. Check for error messages in browser console
4. Refer to `SECURITY_SETUP.md` for detailed troubleshooting
