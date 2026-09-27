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
//
//   -- Endereços (autenticado) --
//   GET    /enderecos
//   POST   /enderecos            { rua, numero, complemento, bairro, cidade, pontoReferencia, favorito }
//   PUT    /enderecos/:id
//   DELETE /enderecos/:id
//   POST   /enderecos/:id/favorito
//
//   -- Carrinho (autenticado, de uma loja por vez) --
//   GET    /carrinho
//   POST   /carrinho/itens       { lojaId, produtoId, quantidade, complementos, observacao, substituir }
//   PUT    /carrinho/itens/:id   { quantidade?, complementos?, observacao? }
//   DELETE /carrinho/itens/:id

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

// --- Endereços e Carrinho: dados por usuário (por e-mail da sessão) ---
const enderecosPorUsuario = new Map(); // email -> [endereco]
const carrinhosPorUsuario = new Map(); // email -> { lojaId, lojaNome, itens: [] }

let proximoEnderecoId = 1;
let proximoItemCarrinhoId = 1;

function round2(n) {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function autenticarEmail(req) {
  const auth = req.headers['authorization'] || '';
  const token = auth.replace('Bearer ', '').trim();
  return sessoes.get(token) || null;
}

function enderecosDoUsuario(email) {
  if (!enderecosPorUsuario.has(email)) enderecosPorUsuario.set(email, []);
  return enderecosPorUsuario.get(email);
}

function carrinhoDoUsuario(email) {
  if (!carrinhosPorUsuario.has(email)) {
    carrinhosPorUsuario.set(email, { lojaId: null, lojaNome: null, itens: [] });
  }
  return carrinhosPorUsuario.get(email);
}

function encontrarProduto(lojaId, produtoId) {
  const categorias = mockCardapios[lojaId] || [];
  for (const cat of categorias) {
    const produto = cat.produtos.find((p) => p.id === produtoId);
    if (produto) return produto;
  }
  return null;
}

// Confere as opções escolhidas contra o cardápio de verdade (nunca confia
// só no que o app mandou) e valida min/max de cada grupo.
function resolverComplementos(produto, complementosBrutos) {
  const escolhidos = Array.isArray(complementosBrutos) ? complementosBrutos : [];
  const porGrupo = new Map();

  for (const escolha of escolhidos) {
    const grupo = produto.gruposComplemento.find((g) => g.id === escolha.grupoId);
    if (!grupo) throw new Error('Grupo de complemento inválido.');
    const opcao = grupo.opcoes.find((o) => o.id === escolha.opcaoId);
    if (!opcao) throw new Error('Opção de complemento inválida.');

    if (!porGrupo.has(grupo.id)) porGrupo.set(grupo.id, []);
    porGrupo.get(grupo.id).push({
      grupoId: grupo.id,
      opcaoId: opcao.id,
      nome: opcao.nome,
      preco: opcao.preco,
    });
  }

  for (const grupo of produto.gruposComplemento) {
    const qtd = (porGrupo.get(grupo.id) || []).length;
    if (qtd < grupo.minQtd || qtd > grupo.maxQtd) {
      throw new Error(
        `O grupo "${grupo.titulo}" precisa de ${grupo.minQtd} a ${grupo.maxQtd} opção(ões).`,
      );
    }
  }

  return [...porGrupo.values()].flat();
}

function calcularPrecoItem(produto, complementos, quantidade) {
  const totalComplementos = complementos.reduce((soma, c) => soma + c.preco, 0);
  return round2((produto.precoBase + totalComplementos) * quantidade);
}

function serializarCarrinho(carrinho) {
  const subtotal = carrinho.itens.reduce((soma, i) => soma + i.precoItem, 0);
  const loja = carrinho.lojaId
    ? mockLojas.find((l) => l.id === carrinho.lojaId)
    : null;
  const taxaEntrega = carrinho.itens.length && loja ? loja.taxaEntrega : 0;

  return {
    lojaId: carrinho.lojaId,
    lojaNome: carrinho.lojaNome,
    itens: carrinho.itens.map((i) => ({
      id: i.id,
      produto: i.produto,
      quantidade: i.quantidade,
      observacao: i.observacao,
      complementos: i.complementos,
      precoItem: round2(i.precoItem),
    })),
    subtotal: round2(subtotal),
    taxaEntrega: round2(taxaEntrega),
    total: round2(subtotal + taxaEntrega),
  };
}

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

    // --- Endereços ---
    if (pathname === '/enderecos' && req.method === 'GET') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });
      return enviarJson(res, 200, enderecosDoUsuario(email));
    }

    if (pathname === '/enderecos' && req.method === 'POST') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const corpo = await lerCorpo(req);
      const { rua, numero, complemento, bairro, cidade, pontoReferencia, favorito } = corpo;
      if (!rua || !numero || !bairro || !cidade) {
        return enviarJson(res, 400, {
          error: 'Preencha rua, número, bairro e cidade.',
        });
      }

      const lista = enderecosDoUsuario(email);
      const ehPrimeiro = lista.length === 0;
      const novoFavorito = ehPrimeiro || Boolean(favorito);

      if (novoFavorito) {
        lista.forEach((e) => (e.favorito = false));
      }

      const novo = {
        id: String(proximoEnderecoId++),
        rua,
        numero,
        complemento: complemento || '',
        bairro,
        cidade,
        pontoReferencia: pontoReferencia || '',
        favorito: novoFavorito,
      };
      lista.push(novo);
      return enviarJson(res, 201, novo);
    }

    const enderecoFavoritoMatch = pathname.match(/^\/enderecos\/([^/]+)\/favorito$/);
    if (enderecoFavoritoMatch && req.method === 'POST') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const id = enderecoFavoritoMatch[1];
      const lista = enderecosDoUsuario(email);
      const alvo = lista.find((e) => e.id === id);
      if (!alvo) return enviarJson(res, 404, { error: 'Endereço não encontrado.' });

      lista.forEach((e) => (e.favorito = e.id === id));
      return enviarJson(res, 200, lista);
    }

    const enderecoMatch = pathname.match(/^\/enderecos\/([^/]+)$/);
    if (enderecoMatch && req.method === 'PUT') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const id = enderecoMatch[1];
      const lista = enderecosDoUsuario(email);
      const alvo = lista.find((e) => e.id === id);
      if (!alvo) return enviarJson(res, 404, { error: 'Endereço não encontrado.' });

      const corpo = await lerCorpo(req);
      const { rua, numero, complemento, bairro, cidade, pontoReferencia, favorito } = corpo;
      if (!rua || !numero || !bairro || !cidade) {
        return enviarJson(res, 400, {
          error: 'Preencha rua, número, bairro e cidade.',
        });
      }

      alvo.rua = rua;
      alvo.numero = numero;
      alvo.complemento = complemento || '';
      alvo.bairro = bairro;
      alvo.cidade = cidade;
      alvo.pontoReferencia = pontoReferencia || '';

      if (favorito) {
        lista.forEach((e) => (e.favorito = e.id === id));
      }

      return enviarJson(res, 200, alvo);
    }

    if (enderecoMatch && req.method === 'DELETE') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const id = enderecoMatch[1];
      const lista = enderecosDoUsuario(email);
      const indice = lista.findIndex((e) => e.id === id);
      if (indice === -1) return enviarJson(res, 404, { error: 'Endereço não encontrado.' });

      const [removido] = lista.splice(indice, 1);
      if (removido.favorito && lista.length > 0) {
        lista[0].favorito = true;
      }

      return enviarJson(res, 200, { status: 'removido' });
    }

    // --- Carrinho ---
    if (pathname === '/carrinho' && req.method === 'GET') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });
      return enviarJson(res, 200, serializarCarrinho(carrinhoDoUsuario(email)));
    }

    if (pathname === '/carrinho/itens' && req.method === 'POST') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const corpo = await lerCorpo(req);
      const { lojaId, produtoId, quantidade, complementos, observacao, substituir } = corpo;

      if (!lojaId || !produtoId) {
        return enviarJson(res, 400, { error: 'Loja e produto são obrigatórios.' });
      }

      const loja = mockLojas.find((l) => l.id === String(lojaId));
      if (!loja) return enviarJson(res, 404, { error: 'Loja não encontrada.' });

      const produto = encontrarProduto(String(lojaId), produtoId);
      if (!produto) return enviarJson(res, 404, { error: 'Produto não encontrado.' });
      if (produto.disponivel === false) {
        return enviarJson(res, 400, { error: 'Este produto está indisponível.' });
      }

      const carrinho = carrinhoDoUsuario(email);

      if (
        carrinho.itens.length > 0 &&
        carrinho.lojaId !== String(lojaId) &&
        !substituir
      ) {
        return enviarJson(res, 409, {
          error: 'Seu carrinho tem itens de outra loja.',
          lojaAtualId: carrinho.lojaId,
          lojaAtualNome: carrinho.lojaNome,
        });
      }

      if (carrinho.lojaId !== String(lojaId)) {
        // Loja nova (carrinho estava vazio, ou o cliente confirmou a troca).
        carrinho.itens = [];
        carrinho.lojaId = String(lojaId);
        carrinho.lojaNome = loja.nome;
      }

      let complementosResolvidos;
      try {
        complementosResolvidos = resolverComplementos(produto, complementos);
      } catch (e) {
        return enviarJson(res, 400, { error: e.message });
      }

      const qtd = Number.isFinite(Number(quantidade)) && Number(quantidade) > 0
        ? Math.floor(Number(quantidade))
        : 1;

      const item = {
        id: String(proximoItemCarrinhoId++),
        produto,
        quantidade: qtd,
        observacao: typeof observacao === 'string' ? observacao : '',
        complementos: complementosResolvidos,
        precoItem: calcularPrecoItem(produto, complementosResolvidos, qtd),
      };

      carrinho.itens.push(item);
      return enviarJson(res, 201, serializarCarrinho(carrinho));
    }

    const itemCarrinhoMatch = pathname.match(/^\/carrinho\/itens\/([^/]+)$/);
    if (itemCarrinhoMatch && req.method === 'PUT') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const id = itemCarrinhoMatch[1];
      const carrinho = carrinhoDoUsuario(email);
      const item = carrinho.itens.find((i) => i.id === id);
      if (!item) return enviarJson(res, 404, { error: 'Item não encontrado no carrinho.' });

      const corpo = await lerCorpo(req);
      const { quantidade, complementos, observacao } = corpo;

      if (complementos !== undefined) {
        try {
          item.complementos = resolverComplementos(item.produto, complementos);
        } catch (e) {
          return enviarJson(res, 400, { error: e.message });
        }
      }

      if (quantidade !== undefined) {
        const qtd = Number(quantidade);
        if (!Number.isFinite(qtd) || qtd < 1) {
          return enviarJson(res, 400, { error: 'Quantidade inválida.' });
        }
        item.quantidade = Math.floor(qtd);
      }

      if (observacao !== undefined) {
        item.observacao = typeof observacao === 'string' ? observacao : '';
      }

      item.precoItem = calcularPrecoItem(item.produto, item.complementos, item.quantidade);

      return enviarJson(res, 200, serializarCarrinho(carrinho));
    }

    if (itemCarrinhoMatch && req.method === 'DELETE') {
      const email = autenticarEmail(req);
      if (!email) return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });

      const id = itemCarrinhoMatch[1];
      const carrinho = carrinhoDoUsuario(email);
      const indice = carrinho.itens.findIndex((i) => i.id === id);
      if (indice === -1) {
        return enviarJson(res, 404, { error: 'Item não encontrado no carrinho.' });
      }

      carrinho.itens.splice(indice, 1);
      if (carrinho.itens.length === 0) {
        carrinho.lojaId = null;
        carrinho.lojaNome = null;
      }

      return enviarJson(res, 200, serializarCarrinho(carrinho));
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