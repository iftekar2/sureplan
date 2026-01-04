console.log("Function is starting...")
import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library'

interface EventInvite {
  id: string;
  event_id: string;
  invitee_id: string;
  status: string;
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: EventInvite;
  schema: string;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // Use service role for internal DB operations
)

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID");
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL");
const FCM_PRIVATE_KEY = Deno.env.get("FCM_PRIVATE_KEY")?.replace(/\\n/g, '\n');

Deno.serve(async (req, connInfo) => {
  const remoteAddr = connInfo.remoteAddr as Deno.NetAddr;
  const clientIp = remoteAddr.hostname;

  console.log(`Function invoked with method: ${req.method} from IP: ${clientIp}`)
  
  if (req.method === 'GET') {
    return new Response(JSON.stringify({ message: "Health check OK. Function is live!" }), { 
      status: 200, 
      headers: { "Content-Type": "application/json" } 
    })
  }

  // 1. Rate Limiting Check
  try {
    const { data: allowed, error: rateLimitError } = await supabase.rpc('check_rate_limit', {
      p_ip_address: clientIp,
      p_endpoint: 'get-event-invite',
      p_max_requests: 60, // 60 requests
      p_window_minutes: 1  // per 1 minute
    });

    if (rateLimitError) {
      console.error('Rate limit check error:', rateLimitError);
    } else if (!allowed) {
      console.warn(`Rate limit exceeded for IP: ${clientIp}`);
      return new Response(JSON.stringify({ error: 'Too Many Requests' }), { 
        status: 429, 
        headers: { "Content-Type": "application/json" } 
      });
    }
  } catch (err) {
    console.error('Unexpected error during rate limiting:', err);
  }

  try {
    const payload: WebhookPayload = await req.json()
    console.log('Received webhook payload:', JSON.stringify(payload, null, 2))

    // 2. Strict Input Validation & Sanitization
    if (!payload || typeof payload !== 'object') {
      return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 });
    }

    if (payload.table !== 'event_invites' || payload.type !== 'INSERT') {
      console.log('Ignoring non-insert event for event_invites table')
      return new Response(JSON.stringify({ message: 'Ignored' }), { status: 200 })
    }

    const { record } = payload;
    if (!record || !record.id || !record.event_id || !record.invitee_id) {
      console.error('Missing required fields in webhook record');
      return new Response(JSON.stringify({ error: 'Incomplete record data' }), { status: 400 });
    }

    // 3. Secure Credential Check
    if (!FCM_PROJECT_ID || !FCM_CLIENT_EMAIL || !FCM_PRIVATE_KEY) {
      console.error('FCM configuration missing in environment variables');
      return new Response(JSON.stringify({ error: 'Server configuration error' }), { status: 500 });
    }

    const {data, error} = await supabase
      .from('user_profiles')
      .select('fcm_token')
      .eq('id', record.invitee_id)
      .single()

    if (error) {
      console.error('Error fetching FCM token from database:', error)
      return new Response(JSON.stringify({ error: 'Database error', details: error }), { status: 500 })
    }

    if (!data || !data.fcm_token) {
      console.error('FCM token not found for record ID:', record.id)
      return new Response(JSON.stringify({ error: 'FCM token not found' }), { status: 404 })
    }

    const fcm_token = data.fcm_token as string
    console.log('Found FCM token:', fcm_token)

    const accessToken = await getAccessToken({
      client_email: FCM_CLIENT_EMAIL, 
      private_key: FCM_PRIVATE_KEY
    })
    console.log('Successfully generated FCM access token')

    const fcmPayload = {
      message: {
        token: fcm_token,
        notification: {
          title: 'New Event Invitation',
          body: 'You have been invited to a new event!',
        },
        data: {
          event_id: record.event_id,
          invite_id: record.id,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        }
      },
    }

    console.log('Sending FCM request to:', `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`)

    const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmPayload),
    })

    const resData = await fcmResponse.json()
    console.log('FCM API Response status:', fcmResponse.status)

    if (!fcmResponse.ok) {
      return new Response(JSON.stringify(resData), { 
        status: fcmResponse.status,
        headers: { "Content-Type": "application/json" }
      })
    }

    return new Response(
      JSON.stringify({ success: true, fcm_response: resData }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (err) {
    console.error('Unexpected error in edge function:', err)
    return new Response(
      JSON.stringify({ error: 'Internal Server Error', message: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})

const getAccessToken = ({client_email, private_key}: {client_email: string, private_key: string}) : Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: client_email, 
      key: private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    jwtClient.authorize((error, token) => {
      if (error || !token) {
        reject(error || new Error('Failed to generate token'))
        return
      }

      resolve(token.access_token!)
    })
  })
}