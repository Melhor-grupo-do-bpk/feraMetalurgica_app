# FERA: perguntas para o cliente

28/10/2026 · levantadas na T8 (acabamento)

O app já funciona com os valores abaixo, que são provisórios. Cada
resposta muda um ponto só, marcado no código com `TODO(cliente)` ou
descrito na decisão citada.

## Valores e regras do orçamento

1. **Margem sobre os custos.** Hoje o valor final é o total de custos
   + 62,5% (R$ 5.200,00 de custos viram R$ 8.450,00). A margem é fixa ou
   muda por orçamento? Ela entra sobre o total ou só sobre parte dos
   custos (por exemplo, sem impostos)?
   *(D-08; `AppConstants.margemPadraoPercentual`)*
2. **Prazo de entrega.** Todo orçamento sai com "15 dias úteis, após
   aprovação e sinal", e nenhuma tela permite mudar. O prazo deve ser
   digitado em cada orçamento? *(D-08; `Orcamento.prazoDiasUteis`)*
3. **Validade.** O PDF diz "Validade: 15 dias". Está certo? Muda por
   orçamento? *(D-04; `AppConstants.validadeOrcamentoDias`)*
4. **Orçamento com custo zero.** Hoje dá para concluir um orçamento com
   todos os custos em R$ 0,00 (valor final R$ 0,00). Bloqueamos, avisamos
   ou deixamos como está? *(HO-T3-01)*
5. **Rascunho.** O wizard só grava o orçamento no fim; sair no meio
   descarta, depois de confirmar. O vendedor precisa salvar um orçamento
   pela metade e continuar depois? *(D-07; `status_orcamento.dart`)*

## Dados da empresa no PDF

6. **Emissor.** O PDF usa os dados do Figma: Fera Metalurgica LTDA, CNPJ
   00.000.000/0001-00, Av. Industrial, 1000 - Galpão 4, São Paulo - SP,
   (11) 99999-9999. Quais são os dados reais? *(D-04;
   `AppConstants.emissor*`)*
7. **Logo.** Temos só o símbolo "F". Precisamos do logo completo, com o
   texto "FERA METALURGICA", em PNG com fundo transparente (ou SVG), para
   o PDF e a tela de abertura. *(D-24)*

## Catálogo

8. **Fotos dos produtos.** As 3 fotos atuais são imagens livres da
   internet, e a do portão é residencial, não um portão basculante
   industrial. Precisamos de fotos reais dos produtos, de preferência em
   16:9. *(HO-T6-01; `assets/images/catalogo/`)*
9. **Produtos.** O catálogo tem 3 itens (Portão Basculante, Estrutura
   Treliçada, Grade de Proteção Pesada). Quais produtos e categorias
   devem entrar, com qual descrição técnica?

## Visual

10. **Cores ajustadas por contraste.** Para que todo texto fique legível
    (contraste mínimo de 4,5:1), algumas cores ficaram um pouco diferentes
    do Figma: o texto do botão "Enviar WhatsApp" é quase preto (o branco
    sobre o verde ficava ilegível), a aba ativa da navegação tem texto
    escuro e o laranja principal ficou um tom mais escuro. A empresa
    aprova? *(D-25)*
