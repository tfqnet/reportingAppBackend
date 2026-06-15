// Edge Function: send-notification
// Triggered by Supabase Database Webhook on reports UPDATE (status change)
// Sends Expo push notifications to the relevant user.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const EXPO_PUSH_URL = 'https://exp.host/--/api/v2/push/send'

interface WebhookPayload {
  type: 'UPDATE'
  table: string
  record: Report
  old_record: Report
}

interface Report {
  id: string
  status: string
  report_number: string
  report_type: string
  submitted_by: string
  approver_id: string
  rejection_reason: string | null
}

interface PushMessage {
  to: string
  title: string
  body: string
  data?: Record<string, unknown>
  sound?: 'default'
  priority?: 'high' | 'normal'
}

serve(async (req: Request) => {
  try {
    const payload: WebhookPayload = await req.json()

    if (payload.type !== 'UPDATE' || payload.table !== 'reports') {
      return new Response('ignored', { status: 200 })
    }

    const newRecord = payload.record
    const oldRecord = payload.old_record

    // Only act on meaningful status transitions
    if (newRecord.status === oldRecord.status) {
      return new Response('no status change', { status: 200 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const messages: PushMessage[] = []

    if (newRecord.status === 'pending') {
      // Notify the assigned approver
      const token = await getPushToken(supabase, newRecord.approver_id)
      if (token) {
        messages.push({
          to: token,
          title: 'New Report Awaiting Approval',
          body: `Report ${newRecord.report_number} has been submitted and requires your review.`,
          data: { reportId: newRecord.id, screen: 'ApprovalQueue' },
          sound: 'default',
          priority: 'high',
        })
      }
    }

    if (newRecord.status === 'approved') {
      // Notify the submitter
      const token = await getPushToken(supabase, newRecord.submitted_by)
      if (token) {
        messages.push({
          to: token,
          title: 'Report Approved',
          body: `Your report ${newRecord.report_number} has been approved.`,
          data: { reportId: newRecord.id, screen: 'ReportDetail' },
          sound: 'default',
          priority: 'high',
        })
      }
    }

    if (newRecord.status === 'rejected') {
      // Notify the submitter with rejection reason
      const token = await getPushToken(supabase, newRecord.submitted_by)
      if (token) {
        messages.push({
          to: token,
          title: 'Report Returned for Revision',
          body: newRecord.rejection_reason
            ? `Report ${newRecord.report_number}: ${newRecord.rejection_reason}`
            : `Report ${newRecord.report_number} was returned. Please review and resubmit.`,
          data: { reportId: newRecord.id, screen: 'ReportDetail' },
          sound: 'default',
          priority: 'high',
        })
      }
    }

    if (messages.length === 0) {
      return new Response('no push tokens found', { status: 200 })
    }

    const response = await fetch(EXPO_PUSH_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      },
      body: JSON.stringify(messages),
    })

    const result = await response.json()
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('send-notification error:', err)
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})

async function getPushToken(
  supabase: ReturnType<typeof createClient>,
  userId: string | null
): Promise<string | null> {
  if (!userId) return null

  const { data } = await supabase
    .from('profiles')
    .select('push_token')
    .eq('id', userId)
    .eq('is_active', true)
    .maybeSingle()

  return data?.push_token ?? null
}
