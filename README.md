# NoBolso

App de finanças pessoais feito em Flutter (Dart) com banco SQLite. Funciona 100% offline:
não tem login, não usa internet e os dados ficam só no celular.

Projeto Integrador 6 de Ciência da Computação, usado também como trabalho final de
Desenvolvimento Mobile.

Equipe: Erick, Grazieli e Gustavo.

## O que o app faz

- Cadastra receitas e despesas (valor, categoria, data, descrição e se é fixa ou não).
- Cadastra categorias próprias, separadas em despesa e receita.
- Cria orçamentos por mês, no total ou por categoria, e avisa ao chegar em 50%, 80% e 100%.
- Mostra 5 gráficos desenhados por nós, sem biblioteca: barras, linha, rosca, medidor e mapa de calor.
- Dá dicas automáticas com base nos gastos.
- No primeiro acesso, mostra um tutorial rápido de 5 passos: escurece a tela, destaca um botão
  e explica numa frase. Dá para pular, e para rever pelo menu lateral.
- Exporta relatório em PDF, Excel (.xlsx) e CSV.

## Como rodar

Precisa ter o Flutter instalado e um emulador Android aberto (ou um celular ligado no PC).
O passo a passo completo, inclusive para configurar um PC do zero, está no [COMO_RODAR.md](COMO_RODAR.md).

```
flutter pub get
flutter run
```

Para rodar os testes:

```
flutter test
```

Para gerar os prints de todas as telas (ficam em `build/telas/`):

```
flutter test tool/capturar_telas_test.dart
```

No Windows, é preciso ligar o Modo de Desenvolvedor (Configurações > Sistema > Para desenvolvedores),
senão o build dá erro.

## Organização do código (MVVM)

O projeto segue o padrão MVVM (Model - View - ViewModel):

- **Model**: as classes de dados (`Lancamento`, `Categoria`, `Orcamento`).
- **View**: as telas. Só montam a interface e repassam os toques para o ViewModel.
- **ViewModel**: guarda o estado da tela (o que está carregado, o filtro escolhido, erros)
  e executa as ações (salvar, excluir, buscar). Quando algo muda, chama `notifyListeners()`
  e a tela se redesenha sozinha pelo `ListenableBuilder`.

O caminho de uma ação é sempre: View → ViewModel → Service ou DAO → SQLite.

```
lib/
  main.dart, app.dart   início do app, tema e navegação (barra de baixo e menu lateral)
  models/               classes de dados
  views/                telas
  viewmodels/           um ViewModel para cada tela
  database/             conexão com o SQLite e os DAOs (todo o SQL fica aqui)
  services/             regras: orçamento, notificações, dicas, gráficos, PDF e planilha
  graphics/             contas dos gráficos (conversão de coordenadas e curvas)
  painters/             desenho dos 5 gráficos no Canvas
  widgets/              pedaços de tela reaproveitados
  utils/                formatação de dinheiro e datas, validações
  theme/                cores e fontes
test/                   testes automatizados
tool/                   script que gera os prints das telas
```

Quando um lançamento é salvo em uma tela, as outras precisam se atualizar. Para isso existe
`utils/eventos.dart`: o ViewModel que salvou dá um aviso e os outros ViewModels que estão
escutando recarregam os dados.

## Banco de dados

SQLite com 5 tabelas, criado em `database/database_helper.dart`:

| Tabela | Para que serve |
|---|---|
| `categorias` | nome, tipo (receita/despesa) e cor |
| `lancamentos` | descrição, valor, tipo, categoria, data e `fixo` (booleano) |
| `orcamentos` | limite por mês, geral ou de uma categoria |
| `alertas_enviados` | quais avisos de orçamento já foram mandados no mês |
| `configuracoes` | nome do usuário e se já viu a tela de boas-vindas |

Algumas escolhas:

- Valores são guardados em centavos (número inteiro) para não ter erro de arredondamento.
- Datas são guardadas como texto `AAAA-MM-DD`, o que deixa filtrar por período com `BETWEEN`.
- O SQLite não tem tipo booleano, então `fixo` é um INTEGER que vale 0 ou 1.
- Não dá para excluir uma categoria que tem lançamentos ou orçamento; o app explica o motivo.
- O banco está na versão 2. Quem tinha a versão 1 ganha a coluna `fixo` automaticamente,
  sem perder dados.

## Requisitos do Projeto Integrador

| Requisito | Onde está |
|---|---|
| RF01 CRUD de lançamentos | `views/lancamento_form_view.dart`, `views/lancamentos_view.dart` |
| RF02 CRUD de categorias | `views/categorias_view.dart` |
| RF03/RF04 Orçamentos, usado e disponível | `services/orcamento_service.dart`, `views/orcamentos_view.dart` |
| RF05 Avisos em 50%, 80% e 100% (uma vez por mês) | `services/notificacao_service.dart`, tabela `alertas_enviados` |
| RF06 Cinco gráficos sem biblioteca | `painters/` e `graphics/` |
| RF07 Dicas automáticas | `services/recomendacao_service.dart` |
| RF08 Exportar PDF, XLSX e CSV | `services/relatorio_pdf_service.dart`, `services/relatorio_planilha_service.dart` |
| RF09 Funciona sem internet | nenhum pacote usa rede |
| RF10 Confirmação ao salvar | SnackBar depois de salvar e indicadores de carregamento |
| RF11 Validação | `utils/validadores.dart` |
| RF12 Lançamento rápido | data já vem como hoje e a descrição é opcional |

## Requisitos do trabalho de Desenvolvimento Mobile

| Pedido no enunciado | Como fizemos em Flutter | Onde aparece |
|---|---|---|
| Label | `Text` | todas as telas |
| Textbox | `TextField` | formulários e campos de busca |
| Button | `FilledButton`, `TextButton`, `IconButton`, `FloatingActionButton` | todas as telas |
| Checkbox | `CheckboxListTile` | "Despesa fixa" no formulário e "Mostrar só os fixos" na lista |
| RadioButton / RadioGroup | `RadioGroup` com `RadioListTile` | formulário de orçamento (geral ou por categoria) |
| ImageView | `Image.asset` | abertura, boas-vindas, menu lateral e tela Sobre |
| ListView | `ListView.builder` | lista de lançamentos |
| Toast / Snackbar | `SnackBar` | confirmações ao salvar, excluir e exportar |
| Grid | `GridView` | categorias em grade |
| Navigation Pages | `Navigator.push` | Lançamentos, Categorias e Sobre |
| Modal | `fullscreenDialog`, `showDialog`, `showModalBottomSheet` | formulários e confirmações |
| Flyout | `Drawer` | menu lateral (botão de menu no topo) |
| Tabbed Pages | `TabBar` e barra de navegação inferior | abas Despesas/Receitas em Categorias e as 4 abas principais |
| CRUD | DAOs e formulários | lançamentos, categorias e orçamentos |
| SQLite com 3+ tabelas (texto, número e booleano) | `sqflite` | ver a seção Banco de dados |
| DAO | `CategoriaDao`, `LancamentoDao`, `OrcamentoDao`, `ConfiguracaoDao` | `database/` |
| Validação nos formulários | `utils/validadores.dart` | valor, categoria, nome e limite |
| Busca em tempo real | o campo avisa o ViewModel a cada letra | Lançamentos (descrição ou categoria, sem precisar de acento) e Categorias |
| Confirmação antes de excluir | `AlertDialog` | lançamentos, categorias e orçamentos |
| MVVM | pastas `models/`, `views/` e `viewmodels/` | ver a seção Organização do código |

## Outras decisões

- A descrição do lançamento é opcional. Se ficar vazia, o app usa o nome da categoria.
- O gráfico de linha mostra o saldo acumulado: por dia no filtro Mês, por semana no Trimestre
  e por mês no Ano.
- No mapa de calor, cada linha é uma semana no filtro Mês e um mês no Trimestre/Ano.
- Se o gasto pular direto de 40% para 100%, só o aviso de 100% é enviado.
- Mudar o limite de um orçamento libera os avisos dele de novo.
- A fonte Roboto vai junto com o app para o PDF aceitar acentos.
- O tutorial foi feito sem biblioteca: o escurecido com o "buraco" em volta do botão é um
  `CustomPainter` (`views/tutorial_view.dart`). Que o tutorial já foi visto fica salvo na
  tabela `configuracoes`.
- No modo debug, o diálogo de perfil tem botões para gerar 100, 1.000 ou 10.000 lançamentos
  de teste.
