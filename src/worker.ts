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
  const municipio = (url.searchParams.get("municipio") || "").trim();
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

  if (municipio) {
    params.set("municipio_slug", `eq.${municipio}`);
  }

  const totalCategorias = 7;

  if (categorias.length > 0 && categorias.length < totalCategorias) {
    params.set("categoria", `in.(${categorias.join(",")})`);
  }

  // Keep city suggestions scoped to the other filters, not to the selected city itself.
  const municipiosParams = new URLSearchParams(params);
  municipiosParams.delete("municipio_slug");
  municipiosParams.set("select", "municipio,municipio_slug");

  apiUrl.search = params.toString();

  const headers = {
    apikey: SUPABASE_KEY,
    Authorization: `Bearer ${SUPABASE_KEY}`,
    Accept: "application/json",
  };

  const municipiosUrl = new URL(apiUrl);
  municipiosUrl.search = municipiosParams.toString();

  const [res, municipiosRes] = await Promise.all([fetch(apiUrl.toString(), {
    headers,
  }), fetch(municipiosUrl.toString(), {
    headers,
  })]);

  if (!res.ok || !municipiosRes.ok) {
    const erro = !res.ok ? res : municipiosRes;
    return Response.json(
      {
        error: "supabase_request_failed",
        status: erro.status,
        details: await erro.text(),
      },
      { status: 502, headers: corsHeaders() },
    );
  }

  const eventos = (await res.json()) as any[];
  const eventosMunicipios = (await municipiosRes.json()) as any[];
  const porCategoria: Record<string, number> = {};
  const porUf: Record<string, number> = {};
  const porMunicipio: Record<string, number> = {};
  const municipios: Record<string, { slug: string; label: string; count: number }> = {};

  for (const evento of eventos) {
    const categoria = evento?.categoria || "outro";
    const ufEvento = evento?.uf || "indefinido";
    porCategoria[categoria] = (porCategoria[categoria] || 0) + 1;
    porUf[ufEvento] = (porUf[ufEvento] || 0) + 1;
  }

  for (const evento of eventosMunicipios) {
    const municipioEvento = evento?.municipio_slug || evento?.municipio || "indefinido";
    const municipioSlug = municipioEvento || "indefinido";
    const municipioLabel = evento?.municipio || evento?.municipio_slug || "Indefinido";
    porMunicipio[municipioSlug] = (porMunicipio[municipioSlug] || 0) + 1;
    municipios[municipioSlug] = {
      slug: municipioSlug,
      label: municipioLabel,
      count: (municipios[municipioSlug]?.count || 0) + 1,
    };
  }

  const municipiosOrdenados = Object.values(municipios)
    .filter((item) => item.slug !== "indefinido")
    .sort((a, b) => b.count - a.count || a.label.localeCompare(b.label, "pt-BR"));

  return Response.json(
    {
      total: eventos.length,
      alertas_ativos: eventos.filter((evento) => evento?.alerta_enviado).length,
      por_categoria: porCategoria,
      por_uf: porUf,
      por_municipio: porMunicipio,
      municipios: municipiosOrdenados,
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
