# Security Fixes & Configuration Guide

## Critical Security Fixes Applied

This branch implements essential security fixes to prevent unauthorized access to sensitive booking data.

### Issues Fixed

1. **Admin Route Protection**: `/admin` and subroutes now require authenticated admin users with proper role-based access control
2. **RLS Policies Tightened**: Supabase Row Level Security now properly restricts data access
3. **Restaurant Scoping**: Admin queries are scoped to site-specific restaurant ID
4. **Dynamic Time Slots**: Booking time slots now generated from config instead of hard-coded values
5. **Tagline Display**: Config tagline now shown in hero section

---

## Required Database Migration

**CRITICAL**: You must run the following SQL migration in your Supabase SQL editor:

### Option 1: Run Migration via Supabase CLI (Recommended)

```bash
supabase db push
```

### Option 2: Manual SQL Execution

If you don't have the Supabase CLI, open the Supabase Dashboard → SQL Editor and run:

**File**: `supabase/migrations/20261019000000_tighten_security_rls.sql`

This migration:
- Drops overly permissive RLS policies that allowed anyone to view bookings
- Creates strict policies where:
  - Anonymous users can ONLY insert bookings (for customer booking form)
  - Anonymous users can ONLY read active restaurants (public info)
  - Only authenticated admin users can view/update/delete bookings
  - Only authenticated admin users can manage restaurants, businesses, customers, and profiles
- Secures tables, profiles, businesses, and customers with proper admin-only access

**Security Impact**: After running this migration, the admin dashboard will only be accessible to users with `role = 'admin'` in the `profiles` table.

---

## Required Configuration Updates

### 1. Set Restaurant ID in Site Config

**File**: `src/config/site.ts`

Update the `restaurantId` field with your restaurant's UUID from the Supabase `restaurants` table:

```typescript
business: {
  name: "Woodman and Olive",
  logoText: "TP",
  tagline: "Restaurant Table Bookings",
  restaurantId: "YOUR-RESTAURANT-UUID-HERE", // ⚠️ REQUIRED: Update this!
},
```

**To find your restaurant ID**:
1. Open Supabase Dashboard → Table Editor
2. Click on `restaurants` table
3. Find your restaurant row
4. Copy the `id` column value (UUID format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

**Security Impact**: Without this ID set, the admin dashboard will show a warning and may display bookings from ALL restaurants (if any admin policies permit cross-restaurant viewing).

---

### 2. Configure Opening Hours (Optional but Recommended)

**File**: `src/config/site.ts`

The time slot generator now uses these config values:

```typescript
hours: {
  display: "Daily: 11:00 AM - 10:00 PM",
  openingTime: "11:00",      // 24h format
  closingTime: "22:00",       // 24h format
  lastBooking: "19:30",       // Last booking time (accounts for 2.5hr meal duration)
},
```

Adjust these times to match your restaurant's actual operating hours.

---

### 3. Update Contact Information

**File**: `src/config/site.ts`

Replace placeholder contact details:

```typescript
contact: {
  phone: "",     // TODO: Add phone number
  email: "",     // TODO: Add email address
  address: "Address to be confirmed",  // TODO: Add full address
},
```

---

## How to Grant Admin Access to Users

After running the migration, users need the `admin` role in the `profiles` table to access the admin dashboard.

### Grant Admin Access via SQL

Run this in Supabase SQL Editor:

```sql
-- Replace 'user@example.com' with the actual user's email
UPDATE profiles 
SET role = 'admin' 
WHERE user_id = (
  SELECT id FROM auth.users WHERE email = 'user@example.com'
);
```

### Grant Admin Access via Table Editor

1. Go to Supabase Dashboard → Table Editor → `profiles`
2. Find the user's row (match by `user_id` to `auth.users.id`)
3. Click the row to edit
4. Change `role` to `admin`
5. Save

---

## Testing the Security Fixes

### Test 1: Anonymous Access Blocked
1. Open incognito/private browser window
2. Navigate to `https://tablepilot.co.uk/woodmanandolive/admin`
3. **Expected**: Redirect to login page with "Authentication Required" message
4. **Fail**: If admin dashboard loads with booking data visible

### Test 2: Non-Admin User Blocked
1. Sign up a new user account (or use a test account)
2. Do NOT set `role = 'admin'` in profiles table for this user
3. Try to access `/admin`
4. **Expected**: "Access Denied" page shown
5. **Fail**: If admin dashboard loads

### Test 3: Admin User Access Granted
1. Ensure your user has `role = 'admin'` in profiles table
2. Sign in and navigate to `/admin`
3. **Expected**: Admin dashboard loads successfully
4. **Expected**: Only bookings for your configured restaurant ID are shown

### Test 4: Customer Booking Still Works
1. Open incognito/private browser window
2. Navigate to home page (not /admin)
3. Try to create a booking as a customer
4. **Expected**: Booking form works and booking is created successfully
5. **Fail**: If you get permission errors

---

## Rollback Instructions

If you need to rollback these changes:

### Revert Code Changes
```bash
git checkout main
git pull
```

### Revert Database Migration
Run this SQL to restore permissive policies (NOT RECOMMENDED FOR PRODUCTION):

```sql
-- WARNING: This restores the security vulnerability
DROP POLICY IF EXISTS "Anonymous users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Admin users can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Admin users can update bookings" ON bookings;
DROP POLICY IF EXISTS "Admin users can delete bookings" ON bookings;

-- Restore old permissive policy (INSECURE)
CREATE POLICY "Bookings are viewable by everyone" ON bookings
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create bookings" ON bookings
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

---

## Support & Questions

If you encounter issues:
1. Check Supabase logs for RLS policy violations
2. Verify user has `role = 'admin'` in profiles table
3. Verify `restaurantId` is set correctly in `src/config/site.ts`
4. Check browser console for error messages

---

## Summary of Files Changed

- ✅ `src/components/AdminGuard.tsx` (new) - Route guard for admin pages
- ✅ `src/App.tsx` - Wrapped admin routes with AdminGuard
- ✅ `src/config/site.ts` - Added restaurantId & structured hours
- ✅ `src/services/supabaseBookingService.ts` - Dynamic time slot generation
- ✅ `src/components/HeroSection.tsx` - Show tagline
- ✅ `src/components/AdminDashboard.tsx` - Scoped to restaurant ID + warning
- ✅ `supabase/migrations/20261019000000_tighten_security_rls.sql` (new) - Security fixes
