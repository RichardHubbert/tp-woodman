import { useAuth } from './useAuth';
import { useMemo, useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';

export const useAdmin = () => {
  const { user } = useAuth();
  const [userRole, setUserRole] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchUserRole = async () => {
      if (!user) {
        setUserRole(null);
        setIsLoading(false);
        return;
      }

      try {
        // Use tp_is_admin() RPC to check if user is admin
        const { data: isAdminResult, error: adminError } = await supabase.rpc('tp_is_admin');

        if (adminError) {
          console.error('Error checking admin status:', adminError);
          setUserRole(null);
          setIsLoading(false);
          return;
        }

        // If user is admin, set role to 'admin', otherwise try to fetch their actual role
        if (isAdminResult === true) {
          setUserRole('admin');
        } else {
          // Fetch user's own profile to get their role
          const { data: profile, error } = await supabase
            .from('profiles')
            .select('role')
            .eq('user_id', user.id)
            .single();

          if (error) {
            console.error('Error fetching user role:', error);
            setUserRole(null);
          } else {
            setUserRole(profile?.role || null);
          }
        }
      } catch (error) {
        console.error('Error fetching user role:', error);
        setUserRole(null);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUserRole();
  }, [user]);

  const isAdmin = useMemo(() => {
    if (!user || !userRole) return false;
    
    // Check if user has admin role
    return userRole === 'admin';
  }, [user, userRole]);

  return { isAdmin, user, userRole, isLoading };
}; 