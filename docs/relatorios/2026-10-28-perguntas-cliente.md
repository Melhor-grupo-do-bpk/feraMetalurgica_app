# FERA: perguntas para o cliente

28/10/2026 · levantadas na T8 (acabamento) · revistas em 31/10/2026, na
V2-G (acabamento da rodada v2)

O app já funciona como descrito em cada pergunta. Cada resposta muda um
ponto só, descrito na decisão citada.

## Em aberto

### Documento do cliente (PDF e WhatsApp)

1. **Custo dos materiais no PDF.** O PDF e a prévia mostram cada produto
   com quantidade, preço unitário e total, os adicionais (insumos,
   impostos, combustível, outros), o desconto e o total geral. O custo de
   cada peça e de cada material **não** aparece: fica só na tela, com
   "Mostrar peças e custos". O cliente deve ver o detalhe das peças, ou
   só os materiais usados, sem preço? *(D-39)*
2. **Mensagem do WhatsApp.** A mensagem leva a saudação, o código (com a
   revisão), o nome da empresa, o total geral e a validade (se houver),
   sem os produtos. Está bom assim?
   *(D-39, D-15)*
3. **Layout do PDF.** O PDF mudou só os dados (produtos, adicionais,
   empresa cadastrada); o desenho é o mesmo do beta. O redesenho do
   documento comercial ficou para outra etapa. Há um modelo que a empresa
   já usa? *(prompt §10)*
4. **Prazo de entrega.** O prazo saiu do orçamento. Quem quiser
   informá-lo escreve nas observações, que vão para o PDF. Precisa de um
   campo próprio? *(D-26)*

### Orçamentos

5. **Histórico das revisões.** Editar um orçamento grava a revisão nova no
   lugar da anterior ("rev. 2"); a versão antiga não fica guardada. A
   empresa precisa consultar as revisões anteriores? *(D-30)*

### Agenda

6. **Lembrete e visão de semana.** A agenda ganhou a aba própria, o
   "Agendar" a partir do orçamento e o aviso de tarefas atrasadas. Ficaram
   para depois o lembrete no celular antes da tarefa (exige permissão de
   notificação) e a visão de semana. Algum dos dois é prioridade?
   *(v2-plano §6, itens 5 e 6)*

### Visual

7. **Logo.** Temos só o símbolo "F". Precisamos do logo completo, com o
   texto "FERA METALURGICA", em PNG com fundo transparente (ou SVG), para
   o PDF e a tela de abertura. *(D-24)*
8. **Cores ajustadas por contraste.** Para que todo texto fique legível
   (contraste mínimo de 4,5:1), algumas cores ficaram um pouco diferentes
   do Figma: o texto do botão "Enviar WhatsApp" é quase preto (o branco
   sobre o verde ficava ilegível), a aba ativa da navegação tem texto
   escuro e o laranja principal ficou um tom mais escuro. Os botões dos
   diálogos ("Cancelar", "Entendi") estão no laranja do app sobre fundo
   branco. A empresa aprova? *(D-25)*

## Já resolvidas na rodada v2

| Pergunta de 28/10 | Como ficou |
|---|---|
| Margem sobre os custos | Saiu. O preço é o preço base de cada produto mais os materiais das peças, os adicionais e o desconto (D-26). |
| Prazo de entrega fixo | Saiu do orçamento; vai nas observações, se preciso (D-26). Ver a pergunta 4. |
| Validade fixa de 15 dias | Campo opcional por orçamento, em dias; sem ele, o PDF e o WhatsApp não mostram a linha (D-26, D-30). |
| Orçamento com total zero | Permitido, com um destaque para conferir antes de salvar (prompt §6, D-34). |
| Rascunho | Não há rascunho salvo: sair do wizard pede confirmação e descarta (prompt §10). |
| Dados do emissor no PDF | Vêm do cadastro "Dados da empresa"; sem ele, não dá para criar orçamento (D-26, D-38). |
| Fotos e produtos do catálogo | O catálogo saiu do app; cada orçamento descreve os produtos e as peças (D-31). |
