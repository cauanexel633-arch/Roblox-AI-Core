# Roblox AI Core 2.0 — AI Weapon Creator

FastAPI + OpenRouter + Roblox Luau. A IA agora projeta uma ficha completa de arma (aparência, combate, estilo de animação e tema da interface), pesquisa referências visuais com metadados de licença aberta e entrega os dados ao servidor Roblox. O Roblox constrói e executa o jogo com módulos locais e allowlists. **Nenhum código Lua gerado pela IA é executado.**

## Arquitetura 2.0

```text
Roblox Creator UI (LocalScript)
        |
        v
GenerateWeapon (RemoteFunction)
        |
        v
AIWeaponServer (servidor Roblox)
        | HTTPS + Secret
        v
FastAPI /v1/weapons/generate
        |
        +--> Wikimedia Commons DesignResearch (opcional, falha não bloqueia)
        |
        +--> OpenRouter (JSON estruturado)
        |
        v
WeaponSpec validado
        |
        v
WeaponFactory -> Tool 3D + atributos + efeitos visuais
WeaponCombat  -> dano, alcance, cooldown e habilidade no servidor
WeaponHUD     -> controles e tema de interface PC/mobile
```

### O que a IA decide
- Nome, descrição, tipo, raridade, dano, cooldown, alcance e habilidade.
- Silhueta, material, padrão, cores, partículas, nível de detalhe e motivo visual.
- Estilo de animação sugerido e tema de interface.
- Estilo de ataque, combo, raio de efeito e knockback, sempre dentro de limites.

### O que o runtime Roblox executa
- Construção procedural de espadas, cajados, arcos e manoplas.
- Partículas, luzes, trail e detalhes geométricos.
- Ataque básico e habilidade especial com verificação de dano no servidor.
- HUD responsivo com botão de ataque e habilidade (tecla Q no PC e botão touch).
- Interface de criação com TextBox, estado de carregamento e retorno do resultado.

## Pesquisa visual híbrida

O backend pesquisa o Wikimedia Commons e devolve referências com título, descrição, miniatura, página de origem, autor e licença. O modelo recebe os metadados textuais como inspiração; os links ficam disponíveis no retorno da API para inspeção humana.

A pesquisa não baixa nem importa imagens automaticamente para o Roblox. O modelo não recebe pixels das imagens nesta versão: a pesquisa é baseada em títulos e descrições. A biblioteca procedural aprovada fica no código do `WeaponFactory` (materiais, geometrias, partículas e padrões). Falha no Wikimedia Commons não bloqueia a criação.

São filtradas licenças permissivas (CC0, domínio público, CC BY e CC BY-SA); licenças NC/ND são excluídas. Confira a página e as obrigações de atribuição antes de reutilizar qualquer arquivo visual.

## Estrutura de arquivos

```text
backend/
  app/
    main.py
    schemas/weapon.py
    services/openrouter.py
    services/design_research.py
roblox/
  ServerScriptService/
    AIWeaponServer.server.lua
    WeaponFactory.lua
    WeaponCombat.server.lua
  StarterPlayer/StarterPlayerScripts/
    WeaponCreator.client.lua
    WeaponHUD.client.lua
  ReplicatedStorage/
    AIWeaponRemote.lua (helper opcional)
```

## 1. Backend no Windows

Requisitos: Python 3.11/3.12, Roblox Studio, conta OpenRouter.

Abra PowerShell na pasta `backend`:

```powershell
py -3.12 -m venv .venv
.\\.venv\\Scripts\\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env
```

Configure `OPENROUTER_API_KEY` e `ROBLOX_AI_CORE_KEY` em `.env`. Gere o segredo Roblox:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Inicie o backend:

```powershell
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Teste `http://127.0.0.1:8000/health`. A documentação fica em `http://127.0.0.1:8000/docs`.

## 2. Deploy Vercel

O backend continua usando o mesmo endpoint `POST /v1/weapons/generate`, então a URL existente permanece compatível. Faça deploy do commit atualizado e confirme `/health` com versão `2.0.0`.

Variáveis de ambiente:
- `OPENROUTER_API_KEY`
- `ROBLOX_AI_CORE_KEY`
- `OPENROUTER_MODEL` (opcional; padrão atual do projeto: `openrouter/free`)
- `OPENROUTER_SITE_URL` (opcional)
- `OPENROUTER_APP_NAME` (opcional)

A pesquisa Commons não exige chave. Se estiver indisponível, a geração continua sem referências.

## 3. Instalação no Roblox Studio

Ative `Allow HTTP Requests` em Experience Settings > Security.

Crie/atualize a hierarquia:
1. `ServerScriptService/AIWeaponServer.server.lua` — Script.
2. `ServerScriptService/WeaponFactory.lua` — ModuleScript.
3. `ServerScriptService/WeaponCombat.server.lua` — Script.
4. `StarterPlayer/StarterPlayerScripts/WeaponCreator.client.lua` — LocalScript.
5. `StarterPlayer/StarterPlayerScripts/WeaponHUD.client.lua` — LocalScript.

Cole os arquivos correspondentes do repositório. O servidor cria automaticamente `ReplicatedStorage.GenerateWeapon` e `ReplicatedStorage.WeaponAction`.

No Creator Dashboard/Studio, configure o Secret `ROBLOX_AI_CORE_KEY` com o mesmo valor de `ROBLOX_AI_CORE_KEY` do backend e autorize o domínio HTTPS `roblox-ai-core.vercel.app`. O segredo nunca deve estar em LocalScripts.

**Importante:** remova/desative scripts antigos que também definem `GenerateWeapon.OnServerInvoke` ou constroem a mesma arma. Deve existir apenas um servidor responsável pela geração.

## 4. Teste

1. Publique/deploy o backend e confirme `/health` com versão 2.0.0.
2. Inicie um teste Play no Studio.
3. Clique em **CRIAR ARMA IA**.
4. Descreva uma arma com pelo menos 5 caracteres.
5. Aguarde a pesquisa e a geração. A Tool deve aparecer na Backpack.
6. Equipe a arma. O HUD deve mostrar atributos; ataque com clique/botão e use habilidade com Q ou botão touch.
7. Verifique Output do servidor para mensagens de inicialização/erros.

## 5. Segurança e limitações desta versão

- OpenRouter e segredo de backend ficam fora do cliente.
- O servidor Roblox valida campos e limites antes de construir a Tool.
- Dano, cooldown, alcance e alvos são verificados no servidor. O cliente só solicita a ação.
- O modelo nunca retorna código executável, scripts, require ou IDs arbitrários de assets.
- Os metadados de pesquisa externa são tratados como dados não confiáveis.
- Os efeitos e geometria são procedurais e usam recursos Roblox nativos; não há upload automático de malhas, texturas, sons ou animações personalizadas.
- `animation_style` é uma direção de animação escolhida pela IA, ainda não uma animação customizada publicada. Animações próprias exigem assets de animação aprovados ou implementação procedural adicional.
- Inventário persistente/DataStore, comércio e economia ainda não fazem parte desta entrega.
- A pesquisa Commons é best-effort; referências podem ser vazias e precisam de revisão humana.
- `openrouter/free` tem disponibilidade e capacidades variáveis. Se o modelo não respeitar o schema, a validação rejeita a geração.
- O rate limit atual é em memória e não distribuído entre instâncias Vercel.

## Documentação oficial

- Roblox RemoteEvents/RemoteFunctions: https://create.roblox.com/docs/scripting/events/remote
- Segurança client-server: https://create.roblox.com/docs/scripting/security/client-server-boundary
- HttpService: https://create.roblox.com/docs/reference/engine/classes/HttpService
- Wikimedia Commons API: https://www.mediawiki.org/wiki/API:Search
