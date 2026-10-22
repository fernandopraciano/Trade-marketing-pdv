const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = 3000;
const PUBLIC_DIR = __dirname;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

function decodeHtmlEntities(str) {
  if (!str) return '';
  return str
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ');
}

function parseProductsFromHtml(html, sourceUrl) {
  const products = [];
  const seenNames = new Set();

  // 1. JSON-LD Parser (Schema.org Product / ItemList)
  const jsonLdRegex = /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let match;
  while ((match = jsonLdRegex.exec(html)) !== null) {
    try {
      const data = JSON.parse(match[1]);
      const processItem = (item) => {
        if (!item) return;
        const type = item['@type'];
        if (type === 'Product' || (type && Array.isArray(type) && type.includes('Product'))) {
          const name = decodeHtmlEntities(item.name || '').trim();
          if (!name || seenNames.has(name.toLowerCase())) return;

          let precoCheio = 0;
          let precoPix = 0;

          const offers = item.offers;
          if (offers) {
            if (offers.highPrice && offers.lowPrice) {
              precoCheio = parseFloat(offers.highPrice);
              precoPix = parseFloat(offers.lowPrice);
            } else if (offers.price) {
              const p = parseFloat(offers.price);
              if (offers.listPrice && parseFloat(offers.listPrice) > p) {
                precoCheio = parseFloat(offers.listPrice);
                precoPix = p;
              } else {
                precoCheio = p;
                precoPix = Math.round(p * 0.90 * 100) / 100;
              }
            } else if (Array.isArray(offers)) {
              const prices = offers.map(o => parseFloat(o.price || 0)).filter(p => p > 0);
              if (prices.length > 0) {
                precoCheio = Math.max(...prices);
                precoPix = Math.min(...prices);
              }
            }
          }

          if (precoPix > 0 || precoCheio > 0) {
            if (!precoPix) precoPix = Math.round(precoCheio * 0.90 * 100) / 100;
            if (!precoCheio || precoCheio <= precoPix) precoCheio = Math.round(precoPix * 1.10 * 100) / 100;

            const category = item.category || (item.brand ? (typeof item.brand === 'string' ? item.brand : item.brand.name) : 'Geral');
            seenNames.add(name.toLowerCase());
            products.push({
              id: 'scraped_' + Date.now() + '_' + (products.length + 1),
              codigo: String(item.sku || item.mpn || ('SKU-' + (products.length + 1).toString().padStart(3, '0'))),
              nome: name,
              descricao: decodeHtmlEntities((item.description || '').replace(/<[^>]*>?/gm, '').trim()).slice(0, 160),
              precoCheio: Number(precoCheio.toFixed(2)),
              precoPix: Number(precoPix.toFixed(2)),
              precoReferencia: Number(precoPix.toFixed(2)),
              categoria: category || 'Geral',
              imagem: item.image ? (typeof item.image === 'string' ? item.image : (Array.isArray(item.image) ? item.image[0] : item.image.url)) : '',
              link: item['@id'] || item.url || sourceUrl || ''
            });
          }
        }
      };

      if (Array.isArray(data)) {
        data.forEach(d => {
          if (d && d.itemListElement && Array.isArray(d.itemListElement)) {
            d.itemListElement.forEach(el => processItem(el.item || el));
          } else {
            processItem(d);
          }
        });
      } else if (data['@type'] === 'ItemList' && Array.isArray(data.itemListElement)) {
        data.itemListElement.forEach(el => processItem(el.item || el));
      } else {
        processItem(data);
      }
    } catch (e) {}
  }

  // 2. VTEX __STATE__ fallback if products count < 2
  if (products.length < 2 && html.includes('__STATE__')) {
    try {
      const stateIdx = html.indexOf('__STATE__');
      const start = html.indexOf('{', stateIdx);
      let depth = 0, end = -1;
      for (let i = start; i < html.length; i++) {
        if (html[i] === '{') depth++;
        else if (html[i] === '}') {
          depth--;
          if (depth === 0) { end = i + 1; break; }
        }
      }
      if (end !== -1) {
        const state = JSON.parse(html.substring(start, end));
        for (const [key, obj] of Object.entries(state)) {
          if (obj && (obj.productName || obj.name) && (key.startsWith('Product:') || key.startsWith('$Product:'))) {
            const name = decodeHtmlEntities(obj.productName || obj.name).trim();
            if (name && !seenNames.has(name.toLowerCase())) {
              let precoCheio = 0;
              let precoPix = 0;

              if (obj.priceRange) {
                if (obj.priceRange.listPrice && obj.priceRange.listPrice.highPrice) {
                  precoCheio = parseFloat(obj.priceRange.listPrice.highPrice);
                }
                if (obj.priceRange.sellingPrice && obj.priceRange.sellingPrice.lowPrice) {
                  precoPix = parseFloat(obj.priceRange.sellingPrice.lowPrice);
                }
              }

              if (!precoPix && !precoCheio) {
                for (const [k, v] of Object.entries(state)) {
                  if (k.includes(obj.productId) && v) {
                    if (v.ListPrice) precoCheio = v.ListPrice;
                    if (v.spotPrice || v.Price) precoPix = v.spotPrice || v.Price;
                  }
                }
              }

              if (precoPix > 0 || precoCheio > 0) {
                if (!precoPix) precoPix = Math.round(precoCheio * 0.90 * 100) / 100;
                if (!precoCheio || precoCheio <= precoPix) precoCheio = Math.round(precoPix * 1.10 * 100) / 100;
                seenNames.add(name.toLowerCase());
                products.push({
                  id: 'scraped_vtex_' + Date.now() + '_' + (products.length + 1),
                  codigo: String(obj.productReference || obj.productId || ('SKU-' + (products.length + 1))),
                  nome: name,
                  descricao: decodeHtmlEntities((obj.description || '').replace(/<[^>]*>?/gm, '').trim()).slice(0, 160),
                  precoCheio: Number(precoCheio.toFixed(2)),
                  precoPix: Number(precoPix.toFixed(2)),
                  precoReferencia: Number(precoPix.toFixed(2)),
                  categoria: (obj.categories && obj.categories[0] ? obj.categories[0].replace(/^\/|\/$/g, '').split('/')[0] : 'Geral'),
                  link: obj.linkText ? (sourceUrl.includes('bemol.com.br') ? `https://www.bemol.com.br/${obj.linkText}/p` : `https://www.tvlar.com.br/${obj.linkText}/p`) : ''
                });
              }
            }
          }
        }
      }
    } catch (e) {}
  }

  // 3. Fallback: Generic HTML cards & price patterns (for other competitor e-commerces)
  if (products.length === 0) {
    const cardRegex = /<(article|div|li)[^>]*class=["'][^"']*(product|item|card|showcase)[^"']*["'][^>]*>([\s\S]*?)<\/\1>/gi;
    let cardMatch;
    while ((cardMatch = cardRegex.exec(html)) !== null && products.length < 30) {
      const cardHtml = cardMatch[3];
      const titleMatch = cardHtml.match(/<(h2|h3|h4|span|a)[^>]*class=["'][^"']*(name|title|description|prod)[^"']*["'][^>]*>([^<]+)<\/\1>/i);
      const name = titleMatch ? decodeHtmlEntities(titleMatch[3].trim()) : null;
      if (!name || name.length < 5 || seenNames.has(name.toLowerCase())) continue;

      const priceMatches = [...cardHtml.matchAll(/R\$\s*([\d\.]+,\d{2})/gi)].map(m => {
        return parseFloat(m[1].replace(/\./g, '').replace(',', '.'));
      }).filter(p => p > 0);

      if (priceMatches.length > 0) {
        let precoCheio = Math.max(...priceMatches);
        let precoPix = Math.min(...priceMatches);
        if (precoPix === precoCheio) {
          precoPix = Math.round(precoCheio * 0.90 * 100) / 100;
        }
        seenNames.add(name.toLowerCase());
        products.push({
          id: 'scraped_html_' + Date.now() + '_' + (products.length + 1),
          codigo: 'SKU-' + (products.length + 1).toString().padStart(3, '0'),
          nome: name,
          descricao: '',
          precoCheio: Number(precoCheio.toFixed(2)),
          precoPix: Number(precoPix.toFixed(2)),
          precoReferencia: Number(precoPix.toFixed(2)),
          categoria: 'Geral',
          link: sourceUrl
        });
      }
    }
  }

  return products;
}

const server = http.createServer(async (req, res) => {
  // CORS Headers para suportar chamadas da aplicação
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost:3000'}`);
  let reqPath = parsedUrl.pathname;

  // Rota de Scraping de E-commerce: /api/scrape?url=...
  if (reqPath === '/api/scrape') {
    const targetUrl = parsedUrl.searchParams.get('url');
    if (!targetUrl) {
      res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: 'Parâmetro "url" é obrigatório.' }));
      return;
    }

    try {
      let finalTargetUrl = targetUrl.trim();
      if (!/^https?:\/\//i.test(finalTargetUrl)) {
        finalTargetUrl = 'https://' + finalTargetUrl;
      }

      const fetchRes = await fetch(finalTargetUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7'
        }
      });

      if (!fetchRes.ok) {
        throw new Error(`Erro HTTP ${fetchRes.status} ao acessar ${finalTargetUrl}`);
      }

      const html = await fetchRes.text();
      let products = parseProductsFromHtml(html, finalTargetUrl);

      // Se for TVLar e não achou produtos pelo HTML estático (ex: categoria client-side), tenta API pública VTEX
      if (products.length === 0 && finalTargetUrl.includes('tvlar.com.br')) {
        try {
          const pathParts = new URL(finalTargetUrl).pathname.split('/').filter(Boolean);
          const searchTerm = pathParts[pathParts.length - 1] || 'ofertas';
          const vtexRes = await fetch(`https://www.tvlar.com.br/api/catalog_system/pub/products/search/${encodeURIComponent(searchTerm)}`, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
          });
          if (vtexRes.ok) {
            const vtexItems = await vtexRes.json();
            if (Array.isArray(vtexItems)) {
              vtexItems.forEach((p, idx) => {
                const item = p.items && p.items[0];
                const offer = item && item.sellers && item.sellers[0] && item.sellers[0].commertialOffer;
                let precoCheio = offer ? (offer.ListPrice || offer.Price || 0) : 0;
                let precoPix = offer ? (offer.spotPrice || offer.Price || precoCheio * 0.95) : precoCheio * 0.95;
                if (precoCheio <= precoPix) precoCheio = Math.round(precoPix * 1.08 * 100) / 100;

                products.push({
                  id: 'scraped_vtex_api_' + Date.now() + '_' + (idx + 1),
                  codigo: String(p.productReference || p.productId || ('SKU-' + (idx + 1))),
                  nome: p.productName,
                  descricao: (p.description || '').replace(/<[^>]*>?/gm, '').trim().slice(0, 160),
                  precoCheio: Number(precoCheio.toFixed(2)),
                  precoPix: Number(precoPix.toFixed(2)),
                  precoReferencia: Number(precoPix.toFixed(2)),
                  categoria: p.categories && p.categories[0] ? p.categories[0].replace(/^\/|\/$/g, '').split('/')[0] : 'TVLar',
                  imagem: item && item.images && item.images[0] ? item.images[0].imageUrl : '',
                  link: p.link || `https://www.tvlar.com.br/${p.linkText}/p`
                });
              });
            }
          }
        } catch (eApi) {}
      }

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        success: true,
        url: finalTargetUrl,
        count: products.length,
        products: products
      }));
      return;
    } catch (err) {
      console.error('Erro no scraper /api/scrape:', err);
      res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: false, error: err.message || 'Falha ao buscar URL' }));
      return;
    }
  }

  // Arquivos estáticos
  if (reqPath === '/' || reqPath === '') reqPath = '/index.html';
  const safePath = path.normalize(reqPath).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(PUBLIC_DIR, safePath);

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      const indexPath = path.join(PUBLIC_DIR, 'index.html');
      fs.readFile(indexPath, (readErr, content) => {
        if (readErr) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('Not Found');
        } else {
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(content);
        }
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
      } else {
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(content);
      }
    });
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor PWA TVLar ativo em http://localhost:${PORT}`);
});
