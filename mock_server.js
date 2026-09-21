// Para rodar:
//   node mock_server.js
//
// Rotas disponíveis:
//   GET  /health
//   POST /auth/cadastro          { nome, email, telefone, senha }
//   POST /auth/login             { email, senha }
//   GET  /auth/me                (com header Authorization: Bearer <token>)
//   POST /auth/invalidar-tokens
//   GET  /lojas                  ?busca= &categoria=
//   GET  /categorias
//   GET  /lojas/:id/cardapio
//   POST /admin/lista-vazia      (liga/desliga lista vazia)

const http = require('http');
const { URL } = require('url');

const PORT = 3000;

const usuarios = []; // { nome, email, telefone, senha }
const sessoes = new Map(); // token -> email

let forcarListaVazia = false;

const mockLojas = [
  {
    id: '1',
    nome: 'Burguer King da Praça',
    categoria: 'Hambúrgueres',
    fotoUrl: 'https://picsum.photos/seed/bk/150',
    tempoEstimadoMin: 35,
    taxaEntrega: 5.9,
    aberta: true,
  },
  {
    id: '2',
    nome: 'Pizza Express',
    categoria: 'Pizzas',
    fotoUrl: 'https://picsum.photos/seed/pizza/150',
    tempoEstimadoMin: 45,
    taxaEntrega: 7.5,
    aberta: true,
  },
  {
    id: '3',
    nome: 'Sushi House',
    categoria: 'Japonesa',
    fotoUrl: 'https://picsum.photos/seed/sushi/150',
    tempoEstimadoMin: 50,
    taxaEntrega: 9.0,
    aberta: false,
  },
  {
    id: '4',
    nome: 'Açaí do Parque',
    categoria: 'Açaí',
    fotoUrl: 'https://picsum.photos/seed/acai/150',
    tempoEstimadoMin: 25,
    taxaEntrega: 0,
    aberta: true,
  },
];

const mockCardapios = {
  '1': [
    {
      id: 'cat_burgers',
      nome: 'Hambúrgueres',
      produtos: [
        {
          id: 'p1',
          nome: 'X-Burguer Artesanal',
          descricao:
            'Pão brioche, carne 180g, queijo cheddar e molho especial.',
          precoBase: 25.0,
          fotoUrl: 'https://picsum.photos/seed/xb/150',
          disponivel: true,
          gruposComplemento: [
            {
              id: 'g_ponto',
              titulo: 'Ponto da carne',
              minQtd: 1,
              maxQtd: 1,
              opcoes: [
                { id: 'op1', nome: 'Ao Ponto', preco: 0.0 },
                { id: 'op2', nome: 'Bem Passado', preco: 0.0 },
              ],
            },
            {
              id: 'g_extras',
              titulo: 'Adicionais',
              minQtd: 0,
              maxQtd: 2,
              opcoes: [
                { id: 'op3', nome: 'Bacon Extra', preco: 4.5 },
                { id: 'op4', nome: 'Queijo Extra', preco: 3.0 },
                { id: 'op5', nome: 'Cebola Caramelizada', preco: 2.5 },
              ],
            },
          ],
        },
        {
          id: 'p2',
          nome: 'X-Salada Especial',
          descricao: 'Produto temporariamente esgotado.',
          precoBase: 22.0,
          fotoUrl: null,
          disponivel: false,
          gruposComplemento: [],
        },
        {
          id: 'p4',
          nome: 'Duplo Cheddar Bacon',
          descricao: 'Dois burgers, cheddar, bacon crocante e molho da casa.',
          precoBase: 32.9,
          fotoUrl: 'https://picsum.photos/seed/duplo/150',
          disponivel: true,
          gruposComplemento: [
            {
              id: 'g_ponto2',
              titulo: 'Ponto da carne',
              minQtd: 1,
              maxQtd: 1,
              opcoes: [
                { id: 'op1b', nome: 'Ao Ponto', preco: 0.0 },
                { id: 'op2b', nome: 'Mal Passado', preco: 0.0 },
              ],
            },
          ],
        },
      ],
    },
    {
      id: 'cat_bebidas',
      nome: 'Bebidas',
      produtos: [
        {
          id: 'p3',
          nome: 'Refrigerante Lata 350ml',
          descricao: 'Coca-Cola ou Guaraná Antarctica.',
          precoBase: 6.0,
          fotoUrl: null,
          disponivel: true,
          gruposComplemento: [
            {
              id: 'g_sabor',
              titulo: 'Sabor',
              minQtd: 1,
              maxQtd: 1,
              opcoes: [
                { id: 'op6', nome: 'Coca-Cola', preco: 0.0 },
                { id: 'op7', nome: 'Guaraná', preco: 0.0 },
                { id: 'op8', nome: 'Sprite', preco: 0.0 },
              ],
            },
          ],
        },
      ],
    },
  ],
  '2': [
    {
      id: 'cat_pizzas',
      nome: 'Pizzas',
      produtos: [
        {
          id: 'pz1',
          nome: 'Margherita',
          descricao: 'Molho de tomate, mussarela e manjericão.',
          precoBase: 39.9,
          fotoUrl: 'https://picsum.photos/seed/marg/150',
          disponivel: true,
          gruposComplemento: [
            {
              id: 'g_tamanho',
              titulo: 'Tamanho',
              minQtd: 1,
              maxQtd: 1,
              opcoes: [
                { id: 't1', nome: 'Média (30cm)', preco: 0.0 },
                { id: 't2', nome: 'Grande (35cm)', preco: 12.0 },
              ],
            },
            {
              id: 'g_borda',
              titulo: 'Borda',
              minQtd: 0,
              maxQtd: 1,
              opcoes: [
                { id: 'b1', nome: 'Catupiry', preco: 8.0 },
                { id: 'b2', nome: 'Cheddar', preco: 8.0 },
              ],
            },
          ],
        },
        {
          id: 'pz2',
          nome: 'Calabresa',
          descricao: 'Calabresa fatiada, cebola e orégano.',
          precoBase: 42.0,
          fotoUrl: null,
          disponivel: true,
          gruposComplemento: [
            {
              id: 'g_tamanho2',
              titulo: 'Tamanho',
              minQtd: 1,
              maxQtd: 1,
              opcoes: [
                { id: 't3', nome: 'Média (30cm)', preco: 0.0 },
                { id: 't4', nome: 'Grande (35cm)', preco: 12.0 },
              ],
            },
          ],
        },
      ],
    },
  ],
  '4': [
    {
      id: 'cat_acai',
      nome: 'Açaí',
      produtos: [
        {
          id: 'a1',
          nome: 'Açaí 500ml',
          descricao: 'Açaí puro batido na hora.',
          precoBase: 18.0,
          fotoUrl: 'https://picsum.photos/seed/acai1/150',
          disponivel: true,
          gruposComplemento: [
            {
              id: 'g_top',
              titulo: 'Toppings',
              minQtd: 0,
              maxQtd: 3,
              opcoes: [
                { id: 'tp1', nome: 'Granola', preco: 2.0 },
                { id: 'tp2', nome: 'Banana', preco: 2.5 },
                { id: 'tp3', nome: 'Leite condensado', preco: 3.0 },
                { id: 'tp4', nome: 'Paçoca', preco: 2.0 },
              ],
            },
          ],
        },
      ],
    },
  ],
};

function gerarToken(email) {
  return `fake-jwt-${email}-${Date.now()}`;
}

function lerCorpo(req) {
  return new Promise((resolve, reject) => {
    let dados = '';
    req.on('data', (chunk) => (dados += chunk));
    req.on('end', () => {
      if (!dados) return resolve({});
      try {
        resolve(JSON.parse(dados));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

function enviarJson(res, status, corpo) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(corpo));
}

const server = http.createServer(async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    return res.end();
  }

  const url = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = url.pathname;

  console.log(`${new Date().toLocaleTimeString()} - ${req.method} ${req.url}`);

  try {
    if (pathname === '/health' && req.method === 'GET') {
      return enviarJson(res, 200, { status: 'ok' });
    }

    if (pathname === '/auth/cadastro' && req.method === 'POST') {
      const { nome, email, telefone, senha } = await lerCorpo(req);
      if (!nome || !email || !telefone || !senha) {
        return enviarJson(res, 400, { error: 'Preencha todos os campos.' });
      }
      if (usuarios.some((u) => u.email === email)) {
        return enviarJson(res, 400, { error: 'E-mail já cadastrado.' });
      }
      usuarios.push({ nome, email, telefone, senha });
      const token = gerarToken(email);
      sessoes.set(token, email);
      return enviarJson(res, 201, { token });
    }

    if (pathname === '/auth/login' && req.method === 'POST') {
      const { email, senha } = await lerCorpo(req);
      const usuario = usuarios.find(
        (u) => u.email === email && u.senha === senha,
      );
      if (!usuario) {
        return enviarJson(res, 401, { error: 'Credenciais inválidas.' });
      }
      const token = gerarToken(email);
      sessoes.set(token, email);
      return enviarJson(res, 200, { token });
    }

    if (pathname === '/auth/me' && req.method === 'GET') {
      const auth = req.headers['authorization'] || '';
      const token = auth.replace('Bearer ', '').trim();
      const email = sessoes.get(token);
      if (!email) {
        return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });
      }
      return enviarJson(res, 200, { email });
    }

    if (pathname === '/auth/invalidar-tokens' && req.method === 'POST') {
      sessoes.clear();
      return enviarJson(res, 200, { status: 'sessões invalidadas' });
    }

    // --- Lojas ---
    if (pathname === '/lojas' && req.method === 'GET') {
      if (forcarListaVazia) {
        return enviarJson(res, 200, []);
      }
      let lista = [...mockLojas];
      const busca = (url.searchParams.get('busca') || '').toLowerCase().trim();
      const categoria = (url.searchParams.get('categoria') || '').trim();
      if (busca) {
        lista = lista.filter((l) => l.nome.toLowerCase().includes(busca));
      }
      if (categoria) {
        lista = lista.filter((l) => l.categoria === categoria);
      }
      return enviarJson(res, 200, lista);
    }

    if (pathname === '/categorias' && req.method === 'GET') {
      const cats = [...new Set(mockLojas.map((l) => l.categoria))];
      return enviarJson(res, 200, cats);
    }

    // Cardápio: /lojas/:id/cardapio
    const cardapioMatch = pathname.match(/^\/lojas\/([^/]+)\/cardapio$/);
    if (cardapioMatch && req.method === 'GET') {
      const lojaId = cardapioMatch[1];
      const cardapio = mockCardapios[lojaId];
      if (!cardapio) {
        return enviarJson(res, 404, { error: 'Cardápio não encontrado.' });
      }
      return enviarJson(res, 200, cardapio);
    }

    // Admin: alterna lista vazia
    if (pathname === '/admin/lista-vazia' && req.method === 'POST') {
      forcarListaVazia = !forcarListaVazia;
      return enviarJson(res, 200, {
        listaVazia: forcarListaVazia,
        msg: forcarListaVazia
          ? 'Lista de lojas agora retorna vazia'
          : 'Lista de lojas voltou ao normal',
      });
    }

    enviarJson(res, 404, { error: 'não encontrado' });
  } catch (e) {
    console.error(e);
    enviarJson(res, 400, { error: 'corpo da requisição inválido' });
  }
});

server.listen(PORT, () => {
  console.log(`Mock server rodando em http://localhost:${PORT}`);
  console.log(
    'Deixe este terminal aberto enquanto testa o app. Ctrl+C para parar.',
  );
});