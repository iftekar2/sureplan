console.log("Function is starting...")
import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import {createClient} from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library'
import serviceAccount from "./service-account.json" with { type: "json" }

interface EventInvite {
  id: string;
  event_id: string;
  invitee_id: string;
  status: string;
}

interface WebhookPayload {
  type: 'INSERT',
  table: string,
  record: EventInvite,
  schema: string,
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_ANON_KEY")!,
)

Deno.serve(async (req) => {
  console.log(`Function invoked with method: ${req.method}`)
  
  if (req.method === 'GET') {
    return new Response(JSON.stringify({ message: "Health check OK. Function is live!" }), { 
      status: 200, 
      headers: { "Content-Type": "application/json" } 
    })
  }

  try {
    const payload: WebhookPayload = await req.json()
    console.log('Received webhook payload:', JSON.stringify(payload, null, 2))

    if (payload.table !== 'event_invites' || payload.type !== 'INSERT') {
      console.log('Ignoring non-insert event for event_invites table')
      return new Response(JSON.stringify({ message: 'Ignored' }), { status: 200 })
    }

    const {data, error} = await supabase
      .from('user_profiles')
      .select('fcm_token')
      .eq('id', payload.record.invitee_id)
      .single()

    if (error) {
      console.error('Error fetching FCM token from database:', error)
      return new Response(JSON.stringify({ error: 'Database error', details: error }), { status: 500 })
    }

    if (!data || !data.fcm_token) {
      console.error('FCM token not found for record ID:', payload.record.id)
      return new Response(JSON.stringify({ error: 'FCM token not found' }), { status: 404 })
    }

    const fcm_token = data.fcm_token as string
    console.log('Found FCM token:', fcm_token)

    console.log('Loaded service account for project:', serviceAccount.project_id)

    const accessToken = await getAccessToken({client_email: serviceAccount.client_email, private_key: serviceAccount.private_key})
    console.log('Successfully generated FCM access token')

    const fcmPayload = {
      message: {
        token: fcm_token,
        notification: {
          title: 'New Event Invitation',
          body: 'You have been invited to a new event!',
        },
        // Adding data payload for better handling on Android/iOS
        data: {
          event_id: payload.record.event_id,
          invite_id: payload.record.id,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        }
      },
    }

    console.log('Sending FCM request to:', `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`)
    console.log('FCM Payload:', JSON.stringify(fcmPayload, null, 2))

    const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmPayload),
    })

    const resData = await fcmResponse.json()
    console.log('FCM API Response status:', fcmResponse.status)
    console.log('FCM API Response data:', JSON.stringify(resData, null, 2))

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
      if (error) {
        reject(error)
        return
      }

      resolve(token.access_token)
    })
  })
}