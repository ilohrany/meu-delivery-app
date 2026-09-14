
// Para rodar:
//   node mock_server.js
//
// Rotas disponíveis:
//   GET  /health
//   POST /auth/cadastro          { nome, email, telefone, senha }
//   POST /auth/login             { email, senha }
//   GET  /auth/me                (com header Authorization: Bearer <token>)
//   POST /auth/invalidar-tokens  (derruba todas as sessões, útil pra
//                                 testar o cenário de "token expirado")

const http = require('http');

const PORT = 3000;

const usuarios = []; // { nome, email, telefone, senha }
const sessoes = new Map(); // token -> email

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
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(corpo));
}

const server = http.createServer(async (req, res) => {
  console.log(`${new Date().toLocaleTimeString()} - ${req.method} ${req.url}`);

  try {
    if (req.url === '/health' && req.method === 'GET') {
      return enviarJson(res, 200, { status: 'ok' });
    }

    if (req.url === '/auth/cadastro' && req.method === 'POST') {
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

    if (req.url === '/auth/login' && req.method === 'POST') {
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

    if (req.url === '/auth/me' && req.method === 'GET') {
      const auth = req.headers['authorization'] || '';
      const token = auth.replace('Bearer ', '').trim();
      const email = sessoes.get(token);
      if (!email) {
        return enviarJson(res, 401, { error: 'Token inválido ou expirado.' });
      }
      return enviarJson(res, 200, { email });
    }

    
    if (req.url === '/auth/invalidar-tokens' && req.method === 'POST') {
      sessoes.clear();
      return enviarJson(res, 200, { status: 'sessões invalidadas' });
    }

    enviarJson(res, 404, { error: 'não encontrado' });
  } catch (e) {
    enviarJson(res, 400, { error: 'corpo da requisição inválido' });
  }
});

server.listen(PORT, () => {
  console.log(`Mock server rodando em http://localhost:${PORT}`);
  console.log('Deixe este terminal aberto enquanto testa o app. Ctrl+C para parar.');
});
