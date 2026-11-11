# Roblox AI Core — AI Weapon Creator (MVP)

Backend FastAPI + OpenRouter e integração Roblox Luau. A IA gera apenas dados estruturados de arma; o servidor Roblox valida os dados e constrói um Tool localmente. Nenhum código retornado pela IA é executado.

## 1. Requisitos
- Windows 10/11
- Python 3.11 ou 3.12
- Roblox Studio
- Conta OpenRouter e chave em https://openrouter.ai/keys

## 2. Instalar backend no Windows
Abra PowerShell na pasta `backend`:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env
```

Edite `.env` e informe `OPENROUTER_API_KEY`. Gere um segredo de autenticação com:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Copie o resultado para `ROBLOX_AI_CORE_KEY` no `.env`. Não publique esse arquivo e não o envie ao Roblox.

Inicie:

```powershell
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Teste `http://127.0.0.1:8000/health` no navegador. A documentação interativa fica em `http://127.0.0.1:8000/docs`.

## 3. Testar a geração localmente
Em outro PowerShell, substitua `SUA_CHAVE_ROBLOX` pelo mesmo valor configurado em `.env`:

```powershell
$headers = @{ "x-api-key" = "SUA_CHAVE_ROBLOX" }
$body = @{ prompt = "Uma espada de gelo que dispara estilhaços"; player_id = 123456; game_id = "teste" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://127.0.0.1:8000/v1/weapons/generate" -Method Post -Headers $headers -ContentType "application/json" -Body $body
```

## 4. Expor backend para Roblox Studio
Roblox não acessa o localhost do seu PC a partir de servidores publicados. Para teste no Studio, use um túnel HTTPS confiável (por exemplo, Cloudflare Tunnel) apontando para `http://127.0.0.1:8000`, ou hospede o backend em um serviço HTTPS. O computador precisa permanecer ligado enquanto o túnel/local backend estiver em uso.

Configure `API_URL` em `AIWeaponServer.server.lua` com o endereço HTTPS público e `/v1/weapons/generate`.

## 5. Configurar Roblox
1. No Creator Dashboard, abra a experiência e crie um Secret chamado `ROBLOX_AI_CORE_KEY` com o mesmo segredo do `.env`.
2. Autorize o domínio HTTPS do backend para esse Secret.
3. Para testes no Studio, configure também o Secret em `File > Experience Settings > Security > Local Secrets`, se disponível na sua experiência.
4. Ative `Allow HTTP Requests` em `File > Experience Settings > Security`.
5. Crie um Script `AIWeaponServer.server.lua` em `ServerScriptService`.
6. Crie um ModuleScript `WeaponFactory` em `ServerScriptService` e cole o código fornecido.
7. Ajuste `API_URL` para o domínio HTTPS real.
8. Crie uma interface com um TextBox e botão. No LocalScript do botão, invoque `ReplicatedStorage.GenerateWeapon:InvokeServer(texto)` e mostre `result.weapon.name` ou `result.error`.

## 6. Segurança e limitações do MVP
- A chave OpenRouter fica somente no backend.
- O segredo de autenticação Roblox fica no Secrets Store, não em LocalScripts.
- O cliente nunca chama OpenRouter diretamente.
- O servidor Roblox valida tipos, habilidades e dano antes de criar o Tool.
- O backend aplica limites em memória por UserId. Reiniciar o backend zera esses contadores; para produção com múltiplas instâncias, migrar para Redis/limitação distribuída.
- O backend autentica o segredo compartilhado, mas ainda não prova criptograficamente que um pedido veio de um servidor Roblox legítimo. Para produção, adicionar assinatura HMAC por requisição ou gateway autenticado e controles anti-replay.
- O MVP não implementa persistência de armas, inventário, efeitos de combate, moderação completa de texto ou economia.
- `openrouter/free` pode selecionar modelos diferentes ao longo do tempo. Modelos gratuitos têm limites e disponibilidade variável. Para uso público, configure limites próprios e um fallback de erro.
- Não envie dados pessoais dos jogadores para o modelo.

## 7. Próximos passos
1. Interface de criação dentro do jogo.
2. Sistema de habilidades reais no servidor (cooldown, dano, efeitos).
3. Moderação de prompts e nomes.
4. Persistência e inventário.
5. Métricas, logs e limites distribuídos.
