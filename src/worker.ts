export interface Env {
  ASSETS: Fetcher;
}

const SUPABASE_URL = "https://egdbiqfqmkrtmtzwldki.supabase.co";
const SUPABASE_KEY = "sb_publishable_rdgtWJMOIFbFi_NvmtaFwg_W_si270o";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/webhook/eventos-painel") {
      return handleEventosPainel(url);
    }

    return env.ASSETS.fetch(request);
  },
};

async function handleEventosPainel(url: URL): Promise<Response> {
  const horas = Number(url.searchParams.get("horas") || "72");
  const uf = (url.searchParams.get("uf") || "").trim().toUpperCase();
  const categorias = (url.searchParams.get("categorias") || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  const desde = new Date(Date.now() - horas * 60 * 60 * 1000).toISOString();
  const apiUrl = new URL(`${SUPABASE_URL}/rest/v1/eventos`);
  const params = new URLSearchParams();

  params.set("select", "*");
  params.set("order", "atualizado_em.desc");
  params.set("limit", "500");
  params.set("atualizado_em", `gte.${desde}`);

  if (uf) {
    params.set("uf", `eq.${uf}`);
  }

  if (categorias.length > 0 && categorias.length < 8) {
    params.set("categoria", `in.(${categorias.join(",")})`);
  }

  apiUrl.search = params.toString();

  const res = await fetch(apiUrl.toString(), {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      Accept: "application/json",
    },
  });

  if (!res.ok) {
    return Response.json(
      {
        error: "supabase_request_failed",
        status: res.status,
        details: await res.text(),
      },
      { status: 502, headers: corsHeaders() },
    );
  }

  const eventos = (await res.json()) as any[];
  const porCategoria: Record<string, number> = {};
  const porUf: Record<string, number> = {};

  for (const evento of eventos) {
    const categoria = evento?.categoria || "outro";
    const ufEvento = evento?.uf || "indefinido";
    porCategoria[categoria] = (porCategoria[categoria] || 0) + 1;
    porUf[ufEvento] = (porUf[ufEvento] || 0) + 1;
  }

  return Response.json(
    {
      total: eventos.length,
      alertas_ativos: eventos.filter((evento) => evento?.alerta_enviado).length,
      por_categoria: porCategoria,
      por_uf: porUf,
      gerado_em: new Date().toISOString(),
      eventos,
    },
    { headers: corsHeaders() },
  );
}

function corsHeaders() {
  return {
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey",
  };
}
