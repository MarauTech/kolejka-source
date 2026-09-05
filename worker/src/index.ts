export interface Env {
  PLK_API_KEY: string;
}

const UPSTREAM_URL = 'https://pdp-api.plk-sa.pl';

const ALLOWED_PATHS = [
  /^\/api\/v1\/schedules(\/shortened)?$/,
  /^\/api\/v1\/schedules\/route\/.*$/,
  /^\/api\/v1\/schedules\/routes\/.*$/,
  /^\/api\/v1\/operations(\/shortened)?$/,
  /^\/api\/v1\/operations\/train\/.*$/,
  /^\/api\/v1\/operations\/statistics$/,
  /^\/api\/v1\/disruptions(\/shortened)?$/,
  /^\/api\/v1\/dictionaries\/stations$/,
  /^\/api\/v1\/dictionaries\/carriers$/,
  /^\/api\/v1\/dictionaries\/commercial-categories$/,
  /^\/api\/v1\/dictionaries\/stop-types$/,
  /^\/api\/v1\/dictionaries\/cities$/,
  /^\/api\/v1\/data-version$/,
  /^\/api\/v1\/fields\/schedules$/,
  /^\/api\/v1\/fields\/operations$/,
  /^\/api\/v1\/fields\/disruptions$/,
];

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    const isAllowed = ALLOWED_PATHS.some((pattern) => pattern.test(path));
    if (!isAllowed) {
      return new Response('Forbidden: Endpoint not allowed', { 
        status: 403,
        headers: { 'Access-Control-Allow-Origin': '*' }
      });
    }

    const targetUrl = new URL(path + url.search, UPSTREAM_URL);
    
    try {
      const apiResponse = await fetch(targetUrl.toString(), {
        method: request.method,
        headers: {
          'X-API-Key': env.PLK_API_KEY,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      });

      const responseHeaders = new Headers();
      responseHeaders.set('Access-Control-Allow-Origin', '*');
      responseHeaders.set('Content-Type', apiResponse.headers.get('Content-Type') || 'application/json');
      
      const hourlyRemaining = apiResponse.headers.get('X-RateLimit-Hourly-Remaining');
      if (hourlyRemaining) responseHeaders.set('X-RateLimit-Hourly-Remaining', hourlyRemaining);
      
      const dailyRemaining = apiResponse.headers.get('X-RateLimit-Daily-Remaining');
      if (dailyRemaining) responseHeaders.set('X-RateLimit-Daily-Remaining', dailyRemaining);

      const responseBody = await apiResponse.text();

      return new Response(responseBody, {
        status: apiResponse.status,
        headers: responseHeaders,
      });

    } catch (error) {
      return new Response(JSON.stringify({ error: 'Internal Server Error' }), {
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*' 
        }
      });
    }
  },
};
