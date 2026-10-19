-- Security Fix: Tighten Row Level Security policies
-- This migration restricts data access to prevent unauthorized viewing of sensitive booking data

-- ============================================
-- 1. Drop existing overly permissive policies
-- ============================================

-- Drop the existing policy that allows everyone to view all bookings
DROP POLICY IF EXISTS "Bookings are viewable by everyone" ON bookings;
DROP POLICY IF EXISTS "Bookings are viewable by business admin" ON bookings;
DROP POLICY IF EXISTS "Authenticated users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Bookings are manageable by admin" ON bookings;

-- ============================================
-- 2. Create strict RLS policies for bookings
-- ============================================

-- Anonymous users can ONLY insert bookings (for customer-facing booking form)
CREATE POLICY "Anonymous users can create bookings" ON bookings
  FOR INSERT 
  TO anon
  WITH CHECK (true);

-- Authenticated admin users can view all bookings
CREATE POLICY "Admin users can view all bookings" ON bookings
  FOR SELECT 
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Authenticated admin users can update bookings
CREATE POLICY "Admin users can update bookings" ON bookings
  FOR UPDATE
  TO authenticated
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

-- Authenticated admin users can delete bookings
CREATE POLICY "Admin users can delete bookings" ON bookings
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- ============================================
-- 3. Tighten restaurant policies
-- ============================================

-- Drop overly permissive restaurant policies
DROP POLICY IF EXISTS "Restaurants are viewable by everyone" ON restaurants;
DROP POLICY IF EXISTS "Restaurants are manageable by admin" ON restaurants;

-- Anonymous users can only view active restaurants (public info only)
CREATE POLICY "Public can view active restaurants" ON restaurants
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Admin users can manage restaurants
CREATE POLICY "Admin users can manage restaurants" ON restaurants
  FOR ALL
  TO authenticated
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

-- ============================================
-- 4. Secure tables
-- ============================================

-- Ensure tables table has RLS enabled
ALTER TABLE IF EXISTS tables ENABLE ROW LEVEL SECURITY;

-- Drop any existing permissive policies on tables
DROP POLICY IF EXISTS "Tables are viewable by everyone" ON tables;
DROP POLICY IF EXISTS "Tables are manageable by admin" ON tables;

-- Anonymous and authenticated users can view tables (needed for availability check)
CREATE POLICY "Public can view tables" ON tables
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only admins can manage tables
CREATE POLICY "Admin users can manage tables" ON tables
  FOR ALL
  TO authenticated
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

-- ============================================
-- 5. Secure profiles
-- ============================================

-- Drop overly permissive profile policies
DROP POLICY IF EXISTS "Profiles are viewable by owner" ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by business admin" ON profiles;

-- Users can only view their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Admin users can view all profiles
CREATE POLICY "Admin users can view all profiles" ON profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.role = 'admin'
    )
  );

-- Admin users can manage all profiles
CREATE POLICY "Admin users can manage profiles" ON profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.user_id = auth.uid()
      AND p.role = 'admin'
    )
  );

-- ============================================
-- 6. Secure businesses
-- ============================================

-- Drop overly permissive business policies
DROP POLICY IF EXISTS "Businesses are viewable by authenticated users" ON businesses;
DROP POLICY IF EXISTS "Businesses are manageable by admin" ON businesses;
DROP POLICY IF EXISTS "Businesses are manageable by business admin" ON businesses;

-- Only admin users can view businesses
CREATE POLICY "Admin users can view businesses" ON businesses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Only admin users can manage businesses
CREATE POLICY "Admin users can manage businesses" ON businesses
  FOR ALL
  TO authenticated
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

-- ============================================
-- 7. Secure customers
-- ============================================

-- Drop overly permissive customer policies
DROP POLICY IF EXISTS "Customers are viewable by business admin" ON customers;
DROP POLICY IF EXISTS "Customers are manageable by business admin" ON customers;

-- Only admin users can view customers
CREATE POLICY "Admin users can view customers" ON customers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Only admin users can manage customers
CREATE POLICY "Admin users can manage customers" ON customers
  FOR ALL
  TO authenticated
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
