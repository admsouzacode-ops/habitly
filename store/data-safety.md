# Habitly: rascunho do formulário "Segurança dos dados" (Play Console)

Base: versão 1.0.0 (8). Dados do usuário só no aparelho, sem conta ou login, anúncios AdMob
(SDK google_mobile_ads) e assinatura pelo Google Play Billing. Revise antes de enviar. Se um dia
ligarmos login, backup ou verificação da compra no servidor, as respostas mudam.

## Coleta e segurança dos dados
| Pergunta | Resposta |
|---|---|
| O app coleta ou compartilha algum dos tipos de dados do usuário exigidos? | **Sim** (por causa do SDK do AdMob) |
| Todos os dados coletados são criptografados em trânsito? | **Sim** |
| Você oferece uma forma de os usuários pedirem a exclusão dos dados? | **Não**: não há conta nem dados em servidor nosso. Os dados locais são apagados ao desinstalar ou limpar os dados. (Se preferir "Sim", informar o e-mail adm.souzacode@gmail.com.) |
| Compromisso com a política Famílias? | Não se aplica (público 13+) |
| Revisão de segurança independente? | Não |

> Dados que ficam **só no aparelho** e nunca saem dele (hábitos, notas, conclusões) **não contam
> como "coletados"** para o Google Play. Por isso não entram no formulário.

## Tipos de dados (todos via SDK Google Mobile Ads / AdMob)
| Categoria › Tipo | Coletado | Compartilhado | Processamento efêmero? | Obrigatório? | Finalidades |
|---|---|---|---|---|---|
| Local › Local aproximado (derivado do IP) | Sim | Sim | Não | Obrigatório | Publicidade ou marketing; Análise; Prevenção de fraudes, segurança e compliance |
| Atividade no app › Interações no app (anúncios vistos/tocados) | Sim | Sim | Não | Obrigatório | Publicidade ou marketing; Análise; Prevenção de fraudes |
| Informações e desempenho do app › Registros de falhas / Diagnóstico | Sim | Sim | Não | Obrigatório | Análise; Prevenção de fraudes, segurança e compliance |
| Dispositivo ou outros IDs › ID de publicidade / IDs do dispositivo | Sim | Sim | Não | Obrigatório | Publicidade ou marketing; Análise; Prevenção de fraudes, segurança e compliance |

Não coletamos: nome, e-mail, ID de usuário, endereço, telefone, informações financeiras*, saúde e
condicionamento físico, mensagens, fotos e vídeos, áudio, arquivos, agenda, contatos, histórico da
web nem local exato.

\* A compra da assinatura é feita **pelo Google Play**. Dados de pagamento e o histórico de compras
são tratados pelo Google e não pelo app, e o app não envia o token da compra a nenhum servidor nesta
versão. Quando a verificação no backend (`POST /subscriptions/verify/google`) for ligada, marcar
**Informações financeiras › Histórico de compras: coletado, não compartilhado, Funcionalidade do
app / Gerenciamento da conta**.

## Outras declarações da Play Console
- **ID de publicidade** (Conteúdo do app › ID de publicidade): **Sim, o app usa**, para **Publicidade ou
  marketing**. O SDK do AdMob adiciona a permissão `com.google.android.gms.permission.AD_ID`.
- **Anúncios**: contém anúncios = **Sim**.
- **Acesso ao app**: todas as funções disponíveis sem restrições (sem login).
- **Apps de saúde**: não é um app de saúde (é de produtividade e hábitos). Se perguntar, responder que
  não usa Health Connect nem dados de saúde.
- **Permissão de alarme exato**: o app usa `SCHEDULE_EXACT_ALARM` só para lembretes que o próprio
  usuário define. O Android 14+ pede a permissão ao usuário, que o app solicita nas Configurações.
  Não usamos `USE_EXACT_ALARM`.
- **Política de privacidade**: URL pública com o conteúdo de `privacy-policy.html`.

## Pendências antes da produção
- Trocar o App ID e o bloco de anúncio de **teste** do AdMob pelos reais (TODO no AndroidManifest e em
  `providers.dart`) e ligar o app ao AdMob/`app-ads.txt`.
- Publicar a política de privacidade numa URL pública.
- Criar `habitly_premium` (planos `mensal` e `anual` e a oferta de 7 dias) e configurar o perfil de comerciante.
