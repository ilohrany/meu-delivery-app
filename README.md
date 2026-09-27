# Meu Delivery

App em Flutter/Dart. Inclui as tarefas:

- **A01** — Abertura do app, navegação e menus por perfil
- **A02** — Login e cadastro do cliente
- **A03** — Lista de lojas com busca e categorias
- **A04** — Cardápio da loja no app
- **A05** — Endereços do cliente no app
- **A06** — Carrinho com observações e total

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
| `/lojas` | GET | lista de lojas; aceita `?busca=` e `?categoria=` |
| `/categorias` | GET | categorias disponíveis para o filtro |
| `/lojas/:id/cardapio` | GET | cardápio da loja, separado por categoria |
| `/admin/lista-vazia` | POST | liga/desliga o retorno vazio — para demonstrar a tela de "nenhuma loja" |
| `/enderecos` | GET / POST | lista e cria endereços do cliente logado |
| `/enderecos/:id` | PUT / DELETE | edita ou remove um endereço |
| `/enderecos/:id/favorito` | POST | marca como favorito (desmarca o anterior) |
| `/carrinho` | GET | carrinho atual do cliente, com totais calculados pelo servidor |
| `/carrinho/itens` | POST | adiciona item; se houver itens de outra loja, devolve `409` a menos que `substituir: true` |
| `/carrinho/itens/:id` | PUT / DELETE | altera quantidade/complementos/observação, ou remove o item |

Todos os endpoints de `/enderecos*` e `/carrinho*` exigem o header
`Authorization: Bearer <token>` — os dados ficam guardados por usuário
(pela sessão), não por aparelho.

Para demonstrar os estados da tela de lojas:

```bash
# lista vazia (chame de novo para voltar ao normal)
curl -X POST http://localhost:3000/admin/lista-vazia

# falha de rede: simplesmente pare o mock server (Ctrl+C) e puxe
# a lista para baixo no app
```

Para forçar o cenário de token expirado: com o app logado, rode
`curl -X POST http://localhost:3000/auth/invalidar-tokens` e depois reabra
o app (ou tente qualquer ação que valide o token) — ele deve voltar
sozinho pra tela de login, sem travar.

## Estrutura

```
lib/
  main.dart                          # ponto de entrada
  config/app_config.dart             # endereço da API e rotas (único lugar)
  models/
    loja.dart                        # a loja como vem da API
    cardapio.dart                    # categoria/produto/grupo de complemento
    carrinho.dart                    # carrinho e item do carrinho (valores vêm do servidor)
    endereco.dart                    # endereço do cliente
  services/
    token_storage.dart               # guarda/lê/apaga o token no aparelho
    auth_service.dart                # login, cadastro, validação de token
    loja_service.dart                # busca lojas, categorias e cardápio na API
    carrinho_service.dart            # adiciona/altera/remove item do carrinho
    endereco_service.dart            # lista/cria/edita/remove/favorita endereço
  screens/
    splash_screen.dart               # tela de abertura + checa sessão salva
    error_screen.dart                # tela de erro + botão "tentar novamente"
    profile_select_screen.dart       # escolha entre Cliente / Entregador
    client/
      client_home_screen.dart        # menu do cliente + aba "Minha conta" com Sair
      lojas_screen.dart              # lista de lojas, busca e filtro (aba "Lojas")
      cardapio_screen.dart           # cardápio da loja + resumo do carrinho
      produto_detail_modal.dart      # detalhe do produto: complementos, obs., adicionar/editar no carrinho
      carrinho_screen.dart           # carrinho: itens, quantidade, total (aba "Carrinho")
      enderecos_screen.dart          # lista de endereços (aba "Endereços")
      endereco_form_screen.dart      # criar/editar endereço
      auth/login_screen.dart         # tela de login
      auth/register_screen.dart      # tela de cadastro
    delivery/delivery_home_screen.dart # menu do entregador (sem login ainda)
  widgets/
    placeholder_content.dart         # conteúdo genérico das abas sem regra de negócio
    loja_card.dart                   # card da loja (aberta x fechada)
mock_server.js                       # servidor de teste (auth + lojas + cardápio + endereços + carrinho)
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

### A03 — Lista de lojas com busca e categorias

| # | Critério | Onde |
|---|----------|------|
| 1 | Lista vem da API com foto, categoria, tempo e taxa | `services/loja_service.dart` + `models/loja.dart` + `widgets/loja_card.dart` |
| 2 | Aberta e fechada são visualmente distintas, e a fechada não abre | `widgets/loja_card.dart`: card fechado fica com `Opacity(0.45)`, etiqueta "Fechada" e `onTap: null` |
| 3 | A informação de aberta vem do servidor | `Loja.aberta` é lido direto do JSON. Não existe nenhum `DateTime.now()` decidindo isso no app |
| 4 | Busca por nome filtra a lista | `lojas_screen.dart`: campo de busca manda `?busca=` para a API (com espera de 400ms para não chamar a cada letra) |
| 5 | Filtro por categoria funciona e pode ser limpo | Chips de categoria; o chip "Todas" limpa o filtro, e a tela de vazio oferece "Limpar filtros" |
| 6 | Lista vazia e falha de rede têm mensagens diferentes | `_MensagemTela` em `lojas_screen.dart`: ícone e texto distintos para cada caso, e só a falha de rede oferece "Tentar novamente" |

### A04 — Cardápio da loja no app

| # | Critério | Onde |
|---|----------|------|
| 1 | O cardápio vem da API separada por categoria | `services/loja_service.dart` (`getCardapio`) + `screens/client/cardapio_screen.dart` |
| 2 | O produto abre com os grupos de complemento e os preços de cada um | `produto_detail_modal.dart`: cada grupo mostra "Obrigatório · min–max" ou "Opcional · até max" e o preço de cada opção |
| 3 | O limite mínimo e máximo de cada grupo é respeitado na tela | `_toggleOpcao` bloqueia seleção acima do máximo; `_validaLimites` trava o botão de adicionar enquanto o mínimo não for atingido — e o servidor valida de novo (nunca confia só no app) |
| 4 | O preço mostrado soma produto mais complementos escolhidos | `_precoTotal` em `produto_detail_modal.dart`, multiplicado pela quantidade |
| 5 | Produto indisponível aparece marcado e não pode ser adicionado | Etiqueta "Indisponível" na lista e no modal; opções e botão de adicionar ficam desabilitados |

### A05 — Endereços do cliente no app

| # | Critério | Onde |
|---|----------|------|
| 1 | A lista de endereços vem da API e mostra todos os do cliente | `services/endereco_service.dart` (`listarEnderecos`) + `enderecos_screen.dart`, por usuário no mock server |
| 2 | Criar, editar e remover endereço chama a API e a tela reflete o resultado | `endereco_form_screen.dart` (criar/editar) e `_confirmarRemocao` em `enderecos_screen.dart`; a lista só é dada como certa depois que o servidor confirma |
| 3 | Marcar favorito persiste no servidor e desmarca o anterior | `EnderecoService.marcarFavorito` → `POST /enderecos/:id/favorito`; o mock server desmarca todos os outros do mesmo usuário |
| 4 | O favorito vem selecionado por padrão na tela do pedido | `EnderecoService.buscarFavorito()` já pronto para a tela de pedido/checkout usar quando essa tarefa existir |
| 5 | Erro de rede ao salvar mostra mensagem e não perde o que foi digitado | `endereco_form_screen.dart`: no erro, só troca `_erroSalvar` — os `TextEditingController` continuam com o que o cliente digitou, o formulário não fecha |

### A06 — Carrinho com observações e total

| # | Critério | Onde |
|---|----------|------|
| 1 | Adicionar ao carrinho chama a API com quantidade, complementos e observação | `CarrinhoService.adicionarItem` (`POST /carrinho/itens`), acionado pelo botão em `produto_detail_modal.dart` |
| 2 | Os valores exibidos são os que a API devolveu, não somados no aplicativo | `Carrinho`/`ItemCarrinho` só guardam `precoItem`/`subtotal`/`total` vindos do JSON; `carrinho_screen.dart` nunca faz conta de preço, só exibe |
| 3 | Alterar quantidade, editar complementos e remover item atualizam o total | `CarrinhoService.atualizarItem` / `removerItem`, cada um devolve o carrinho já recalculado pelo servidor |
| 4 | Produto de outra loja avisa e só esvazia o carrinho após confirmação | Mock server devolve `409` se a loja for diferente; `produto_detail_modal.dart` mostra o diálogo "Trocar de loja?" e só reenvia com `substituir: true` se o cliente confirmar |
| 5 | O carrinho sobrevive ao fechar e reabrir o aplicativo | O carrinho é guardado no servidor por usuário (não em `SharedPreferences` nem em memória do app) — ao reabrir, `GET /carrinho` devolve o mesmo estado |
| 6 | Carrinho vazio tem tela própria e não deixa avançar | `_MensagemVazia` em `carrinho_screen.dart`; sem itens, o rodapé com total e o botão "Finalizar pedido" nem aparecem |



- **Cliente** — Lojas · Meus pedidos · Endereços · Minha conta (login/cadastro obrigatório antes de entrar)
- **Entregador** — Entregas · Ganhos · Minha conta (ainda sem login — não é o escopo desta tarefa)

## Próximos passos (fora do escopo destas tarefas)

- Login/autenticação do entregador
- Tela de "Meus pedidos" (hoje é placeholder)
- Tela de fechamento de pedido (escolher endereço favorito, forma de pagamento, confirmar) — o botão "Finalizar pedido" no carrinho já está pronto pra ser ligado nela
- Endpoints reais no back-end (o app já está pronto para consumi-los, ajustando só `app_config.dart`)
