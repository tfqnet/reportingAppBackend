// Edge Function: invite-user
// Called by adminService.inviteUser() to create a new auth user and set their profile role.
// Requires service role key — only callable server-side (admin session passes JWT, function verifies role).

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify the caller is an admin
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return json({ error: 'Missing authorization header' }, 401)
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Verify caller's role
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser()
    if (userError || !user) return json({ error: 'Unauthorized' }, 401)

    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profile?.role !== 'admin') {
      return json({ error: 'Forbidden — admin role required' }, 403)
    }

    // Parse request body
    const { email, full_name, role, department_id, company } = await req.json()

    if (!email || !full_name || !role) {
      return json({ error: 'email, full_name, and role are required' }, 400)
    }

    const validRoles = ['end_user', 'approver', 'admin']
    if (!validRoles.includes(role)) {
      return json({ error: `role must be one of: ${validRoles.join(', ')}` }, 400)
    }

    // Create auth user (sends invite email via Supabase)
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
      data: { full_name },
    })

    if (createError) {
      return json({ error: createError.message }, 400)
    }

    // Patch the auto-created profile with role + metadata
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .update({
        full_name,
        role,
        department_id: department_id ?? null,
        company: company ?? null,
      })
      .eq('id', newUser.user!.id)

    if (profileError) {
      return json({ error: profileError.message }, 500)
    }

    return json({ id: newUser.user!.id, email, role, full_name }, 200)
  } catch (err) {
    console.error('invite-user error:', err)
    return json({ error: String(err) }, 500)
  }
})

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
