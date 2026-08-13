// @ts-ignore: Deno npm import specifier
import { withSupabase } from 'npm:@supabase/server@1.4.0'

const allowedPacks = new Set(['operations', 'master_data', 'money', 'reports'])
const redirectTo = 'com.cuboidllc.cuboid_flutter_template://auth-callback'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx: any) => {
    if (req.method !== 'POST') {
      return Response.json({ message: 'Method not allowed.' }, { status: 405 })
    }

    const body = await req.json().catch(() => null)
    const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : ''
    const displayName = typeof body?.displayName === 'string' ? body.displayName.trim() : ''
    const packs: string[] = Array.isArray(body?.accessPacks)
      ? [...new Set<string>(body.accessPacks.filter((pack: unknown): pack is string => typeof pack === 'string'))]
      : []

    if (
      !email.includes('@') ||
      displayName.length < 1 ||
      displayName.length > 120 ||
      packs.length < 1 ||
      packs.some((pack) => !allowedPacks.has(pack))
    ) {
      return Response.json({ message: 'Invitation details are invalid.' }, { status: 400 })
    }

    const { data: owner } = await ctx.supabase
      .from('tenant_members')
      .select('tenant_id')
      .eq('user_id', ctx.userClaims!.id)
      .eq('role', 'owner')
      .eq('status', 'active')
      .maybeSingle()

    if (!owner) {
      return Response.json({ message: 'Owner access is required.' }, { status: 403 })
    }

    const { data: existing } = await ctx.supabaseAdmin
      .from('tenant_members')
      .select('id')
      .eq('tenant_id', owner.tenant_id)
      .eq('email', email)
      .maybeSingle()

    if (existing) {
      return Response.json({ message: 'This email already has access.' }, { status: 409 })
    }

    const { data: invited, error: inviteError } =
      await ctx.supabaseAdmin.auth.admin.inviteUserByEmail(email, {
        data: { display_name: displayName },
        redirectTo,
      })

    if (inviteError || !invited.user) {
      return Response.json({ message: 'The invitation could not be sent.' }, { status: 400 })
    }

    const { data: memberId, error: memberError } = await ctx.supabaseAdmin.rpc(
      'create_invited_member',
      {
        p_tenant_id: owner.tenant_id,
        p_user_id: invited.user.id,
        p_display_name: displayName,
        p_email: email,
        p_invited_by: ctx.userClaims!.id,
        p_packs: packs,
      },
    )

    if (memberError || !memberId) {
      await ctx.supabaseAdmin.auth.admin.deleteUser(invited.user.id)
      return Response.json({ message: 'The invitation could not be saved.' }, { status: 500 })
    }

    return Response.json({ id: memberId }, { status: 201 })
  }),
}
