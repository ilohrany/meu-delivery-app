# Meu Delivery

App em Flutter/Dart. Inclui as tarefas:

- **A01** — Abertura do app, navegação e menus por perfil
- **A02** — Login e cadastro do cliente

## Como rodar

```bash
flutter pub get
flutter run
```

Por padrão a API é procurada em `http://10.0.2.2:3000` (isso é o "localhost"
do seu PC quando roda no emulador Android). Se não tiver um servidor
rodando ali, o app vai cair na tela de erro — isso é esperado e faz parte
do critério de aceite (você pode clicar em "Tentar novamente").

Para apontar para outro endereço, sem editar código:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

### Testando sem o back-end de verdade ainda

O repositório inclui `mock_server.js`, um servidor bem simples (só Node.js,
sem dependências) que simula as rotas que o app já usa. Rode num terminal
separado, deixando ele aberto:

```bash
node mock_server.js
```

Rotas simuladas:

| Rota | Método | Uso |
|------|--------|-----|
| `/health` | GET | checagem de servidor de pé (tarefa A01) |
| `/auth/cadastro` | POST | cria cliente, devolve token |
| `/auth/login` | POST | valida e-mail/senha, devolve token |
| `/auth/me` | GET | valida se o token ainda é válido |
| `/auth/invalidar-tokens` | POST | derruba todas as sessões — útil pra testar o cenário de "token expirado" sem esperar de verdade |

Para forçar o cenário de token expirado: com o app logado, rode
`curl -X POST http://localhost:3000/auth/invalidar-tokens` e depois reabra
o app (ou tente qualquer ação que valide o token) — ele deve voltar
sozinho pra tela de login, sem travar.

## Estrutura

```
lib/
  main.dart                          # ponto de entrada
  config/app_config.dart             # endereço da API e rotas (único lugar)
  services/
    token_storage.dart               # guarda/lê/apaga o token no aparelho
    auth_service.dart                # login, cadastro, validação de token
  screens/
    splash_screen.dart               # tela de abertura + checa sessão salva
    error_screen.dart                # tela de erro + botão "tentar novamente"
    profile_select_screen.dart       # escolha entre Cliente / Entregador
    client/
      client_home_screen.dart        # menu do cliente + aba "Minha conta" com Sair
      auth/login_screen.dart         # tela de login
      auth/register_screen.dart      # tela de cadastro
    delivery/delivery_home_screen.dart # menu do entregador (sem login ainda)
  widgets/placeholder_content.dart   # conteúdo genérico das abas sem regra de negócio
mock_server.js                       # servidor de teste (health + auth)
```

## Onde cada critério de aceite foi atendido

### A01 — Abertura, navegação e menus

| # | Critério | Onde |
|---|----------|------|
| 1 | Tela de abertura com a marca | `screens/splash_screen.dart` |
| 2 | Navegação com menu do cliente e do entregador | `profile_select_screen.dart` + `client/client_home_screen.dart` + `delivery/delivery_home_screen.dart` |
| 3 | Endereço da API em configuração | `config/app_config.dart` (nenhuma URL solta no meio do código) |
| 4 | Sem resposta do servidor → tela de erro + botão de tentar de novo | `screens/error_screen.dart`, disparada pela checagem em `splash_screen.dart` |
| 5 | Roda sem travar ao trocar de tela | Navegação via `Navigator.pushReplacement`, sem estado global que quebre ao trocar de aba |

### A02 — Login e cadastro do cliente

| # | Critério | Onde |
|---|----------|------|
| 1 | Login chama a API de autenticação e guarda o token | `auth/login_screen.dart` → `AuthService.login` → `TokenStorage.salvarToken` |
| 2 | Cadastro cria o cliente pela API e já entra logado | `auth/register_screen.dart` → `AuthService.cadastrar` (usa o token da resposta, ou faz login automático se a API não devolver token) |
| 3 | E-mail ou senha errados mostram mensagem genérica | `AuthService.login` sempre lança `"E-mail ou senha inválidos."`, sem dizer qual campo falhou |
| 4 | Token enviado nas chamadas seguintes + app se mantém logado ao reabrir | `AuthService.tokenValido()` manda o header `Authorization: Bearer <token>` e é chamado pela splash a cada abertura do app |
| 5 | Token expirado ou inválido devolve pra login, sem travar | Se `/auth/me` responde 401, `TokenStorage.limparToken()` é chamado e a splash manda pra `ProfileSelectScreen` |
| 6 | Botão Sair apaga o token do aparelho | Aba "Minha conta" em `client_home_screen.dart` → `AuthService.sair()` |

## Menus por perfil

- **Cliente** — Lojas · Meus pedidos · Endereços · Minha conta (login/cadastro obrigatório antes de entrar)
- **Entregador** — Entregas · Ganhos · Minha conta (ainda sem login — não é o escopo desta tarefa)

## Próximos passos (fora do escopo destas tarefas)

- Login/autenticação do entregador
- Conteúdo real de Lojas, Meus pedidos e Endereços (hoje são placeholders)
- Endpoints reais no back-end (o app já está pronto para consumi-los, ajustando só `app_config.dart`)
