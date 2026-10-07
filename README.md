# NoBolso

App mobile de finanças pessoais, **100% offline**, feito em Flutter + Dart + SQLite para o
Projeto Integrador 6 (Ciência da Computação). Sem conta bancária, sem nuvem, sem login e sem assinatura.

Equipe: Erick, Grazieli e Gustavo.

## Como rodar

**Passo a passo completo (inclusive para configurar um PC do zero): [COMO_RODAR.md](COMO_RODAR.md).**

Pré-requisitos: Flutter SDK (em `C:\src\flutter`), Android Studio com Android SDK e um emulador.

```bash
flutter pub get
flutter run            # com o emulador aberto ou um celular conectado
flutter test           # testes automatizados
flutter test tool/capturar_telas_test.dart   # gera PNGs das telas em build/telas/
```

No Windows, o build com plugins exige o **Modo de Desenvolvedor** ligado
(Configurações → Sistema → Para desenvolvedores).

## Estrutura

```
lib/
├── main.dart, app.dart        # inicialização, tema, navegação inferior
├── theme/app_theme.dart       # paleta verde + neutros claros
├── models/                    # Categoria, Lancamento, Orcamento, Tipo
├── database/                  # database_helper + DAOs (SQLite)
├── services/                  # orçamento, notificações, recomendações, dados dos gráficos,
│                              # PDF, planilha (xlsx/csv), gerador de dados de teste
├── graphics/                  # viewport (mundo → tela) e curvas (Catmull-Rom → Bézier, easing)
├── painters/                  # barras, linha, rosca, medidor, mapa de calor (CustomPainter)
├── screens/                   # telas
├── widgets/                   # componentes reutilizáveis
└── utils/                     # formatadores, validadores, eventos
test/                          # banco, regras, gráficos, formatos/exportação
tool/capturar_telas_test.dart  # capturas de tela sem emulador
```

Camadas: telas → serviços → DAOs → SQLite. O estado das telas usa `setState`; quando os dados mudam,
`Eventos.dadosAlterados` avisa as abas abertas para recarregarem.

## Requisitos atendidos

| Req. | Onde |
|------|------|
| RF01 CRUD de lançamentos | `screens/lancamento_form_screen.dart`, `screens/lancamentos_screen.dart` |
| RF02 CRUD de categorias | `screens/categorias_screen.dart` (ícone de etiqueta no Início ou chip "+ Nova") |
| RF03/RF04 Orçamentos, usado/disponível | `services/orcamento_service.dart`, `screens/orcamentos_screen.dart` |
| RF05 Notificações 50/80/100% (uma vez por mês) | `services/notificacao_service.dart`, tabela `alertas_enviados` |
| RF06 Cinco gráficos sem biblioteca | `painters/` + `graphics/` |
| RF07 Recomendações por regras | `services/recomendacao_service.dart` |
| RF08 PDF, XLSX e CSV conforme filtros | `services/relatorio_pdf_service.dart`, `services/relatorio_planilha_service.dart` |
| RF09 Modo avião | nenhum pacote usa rede; o manifesto não pede permissão de internet no release |
| RF10 Confirmação e carregamento | SnackBar após salvar; indicadores em todas as telas |
| RF11 Validação | `utils/validadores.dart` (valor e categoria antes de salvar) |
| RF12 Fluxo curto | valor digitado sem vírgula; data = hoje; descrição opcional (usa o nome da categoria) |

## Decisões tomadas na implementação (além do plano)

- **Descrição opcional** no formulário: se ficar vazia, grava o nome da categoria (a coluna continua `NOT NULL`).
- **Linha da Análise** mostra o *saldo acumulado* no período: por dia (Mês), por semana (Trimestre) e por mês (Ano).
- **Mapa de calor**: no filtro Mês, as linhas são as semanas; em Trimestre/Ano, cada linha é um mês.
- **Medidor sem orçamento geral**: o "usado" considera só as categorias que têm limite, para comparar com a soma dos limites.
- Se o gasto pular de 40% direto para 100%, só o aviso de 100% é enviado (os níveis menores ficam marcados).
- Editar o limite de um orçamento libera os avisos daquele orçamento de novo.
- Fonte **Roboto** embutida (licença Apache, em `assets/fonts`) para o app e para o PDF aceitar qualquer caractere.
- **Gerador de dados fictícios** (100 / 1.000 / 10.000) no diálogo de perfil, visível só em modo debug.
