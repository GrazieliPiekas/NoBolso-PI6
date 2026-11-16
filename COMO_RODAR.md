# Como rodar o NoBolso (passo a passo para a equipe)

Este guia mostra tudo do zero: o que instalar, como baixar o projeto, como abrir o app no
celular virtual (emulador) e como mandar as suas alterações para o GitHub.

Siga **na ordem** e não pule etapas. Cada etapa termina com um **"Confira"**: só passe para a
próxima se o que aparecer na tela for igual ao que está escrito ali.

---

## Índice

- [Parte 0 - Antes de começar](#parte-0---antes-de-começar)
- [Parte 1 - Conta no GitHub e convite](#parte-1---conta-no-github-e-convite)
- [Parte 2 - Instalar o Git](#parte-2---instalar-o-git)
- [Parte 3 - Instalar o Flutter](#parte-3---instalar-o-flutter)
- [Parte 4 - Ligar o Modo de Desenvolvedor do Windows](#parte-4---ligar-o-modo-de-desenvolvedor-do-windows)
- [Parte 5 - Instalar o Android Studio e criar o celular virtual](#parte-5---instalar-o-android-studio-e-criar-o-celular-virtual)
- [Parte 6 - Conferir se está tudo certo (flutter doctor)](#parte-6---conferir-se-está-tudo-certo-flutter-doctor)
- [Parte 7 - Baixar o projeto](#parte-7---baixar-o-projeto)
- [Parte 8 - Rodar o app](#parte-8---rodar-o-app)
- [Parte 9 - Editor para ler e mexer no código (VS Code)](#parte-9---editor-para-ler-e-mexer-no-código-vs-code)
- [Parte 10 - Trabalhando em grupo com o Git](#parte-10---trabalhando-em-grupo-com-o-git)
- [Parte 11 - Rodar no seu celular de verdade (opcional)](#parte-11---rodar-no-seu-celular-de-verdade-opcional)
- [Parte 12 - Comandos úteis](#parte-12---comandos-úteis)
- [Parte 13 - Deu erro? Problemas comuns](#parte-13---deu-erro-problemas-comuns)
- [Checklist final](#checklist-final)

---

## Parte 0 - Antes de começar

**O que você precisa:**

- Um computador com **Windows 10 ou 11**.
- Pelo menos **20 GB livres** no disco (o Android Studio e o emulador ocupam bastante).
- De preferência **16 GB de memória RAM**. Com 8 GB funciona, mas o emulador fica lento.
- **Internet boa**: vai baixar uns 5 a 8 GB no total.
- Mais ou menos **1 hora e meia** na primeira vez. Quase todo esse tempo é download.

**Como abrir o terminal (vai usar muito):**

1. Aperte a tecla **Windows** do teclado.
2. Digite **cmd**.
3. Clique em **Prompt de Comando**.

Vai abrir uma janela preta. É nela que você digita os comandos deste guia.

**Como digitar um comando:**

- Copie o comando do guia, cole no terminal (botão direito do mouse cola) e aperte **Enter**.
- Espere terminar. Você sabe que terminou quando aparece de novo a linha com o caminho e o
  sinal `>`, por exemplo `C:\Users\SeuNome>`.
- Um comando por vez. Não cole vários de uma vez.

> Se em algum momento um comando pedir para você responder `y/N`, digite `y` e aperte Enter.

---

## Parte 1 - Conta no GitHub e convite

O código do projeto fica guardado no GitHub. Para **baixar** não precisa de conta, mas para
**mandar alterações** precisa.

**Cada colega:**

1. Entre em <https://github.com> e clique em **Sign up**.
2. Crie a conta com seu e-mail (anote o nome de usuário que você escolheu).
3. Mande o seu **nome de usuário do GitHub** para a Grazieli.

**A Grazieli (dona do repositório):**

1. Abra <https://github.com/GrazieliPiekas/NoBolso-PI6>.
2. Clique em **Settings** (engrenagem, no topo do repositório).
3. No menu da esquerda, clique em **Collaborators**.
4. Clique em **Add people**, digite o usuário do colega e confirme.

**Cada colega de novo:**

1. Vai chegar um **e-mail do GitHub** com o convite. Abra e clique em **Accept invitation**.
   (Também aparece no sininho de notificações do site do GitHub.)

**Confira:** abrindo <https://github.com/GrazieliPiekas/NoBolso-PI6>, você vê os arquivos do
projeto e não aparece nenhum aviso de convite pendente.

---

## Parte 2 - Instalar o Git

O Git é o programa que baixa o projeto e envia as alterações para o GitHub.

1. Entre em <https://git-scm.com/download/win>.
2. Clique em **Click here to download** (a versão 64-bit).
3. Abra o arquivo baixado e vá clicando em **Next** em todas as telas, sem mudar nada.
   No final clique em **Install** e depois em **Finish**.
4. **Feche** o terminal se ele estiver aberto e **abra de novo** (o Windows só reconhece
   programas novos em terminais novos).
5. Diga ao Git quem é você. Use o **mesmo nome e e-mail da sua conta do GitHub**
   (troque o texto entre aspas):

   ```
   git config --global user.name "Seu Nome"
   ```

   ```
   git config --global user.email "seu-email@exemplo.com"
   ```

**Confira:** rode o comando abaixo. Tem que aparecer algo como `git version 2.55.0.windows.1`
(o número pode ser outro).

```
git --version
```

---

## Parte 3 - Instalar o Flutter

O Flutter é o que transforma o nosso código em app. Vamos colocá-lo em `C:\src\flutter`.

1. No terminal, crie a pasta:

   ```
   mkdir C:\src
   ```

   Se aparecer "Já existe uma subpasta ou um arquivo C:\src", tudo bem, pode seguir.

2. Baixe o Flutter (demora alguns minutos):

   ```
   git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
   ```

3. Coloque o Flutter na **mesma versão que o projeto usa (3.47.6)**, para ninguém ter
   diferença:

   ```
   git -C C:\src\flutter checkout 3.47.6
   ```

   Vai aparecer um texto falando em "detached HEAD". Está certo, pode ignorar.

4. Agora é preciso avisar o Windows onde o Flutter está (isso se chama "colocar no PATH").
   Abra o **PowerShell**: tecla Windows, digite **powershell**, clique em **Windows PowerShell**.
   Cole este comando inteiro e aperte Enter:

   ```
   [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ';C:\src\flutter\bin', 'User')
   ```

   Não aparece nenhuma mensagem. Isso é normal. Pode fechar o PowerShell.

5. **Feche todos os terminais** e abra um **Prompt de Comando novo**.

**Confira:** rode o comando abaixo. Na primeira vez ele baixa mais algumas coisas e demora um
pouco. No fim tem que aparecer `Flutter 3.47.6 • channel stable`.

```
flutter --version
```

---

## Parte 4 - Ligar o Modo de Desenvolvedor do Windows

Sem isso, o Flutter dá erro na hora de montar o app ("Building with plugins requires symlink
support").

1. Abra as **Configurações** do Windows (tecla Windows + I).
2. Vá em **Sistema** e depois em **Para desenvolvedores**.
   (No Windows 10: **Atualização e Segurança** > **Para desenvolvedores**.)
3. Ligue a chave **Modo de Desenvolvedor** e confirme com **Sim**.

**Confira:** a chave "Modo de Desenvolvedor" está como **Ativado**.

---

## Parte 5 - Instalar o Android Studio e criar o celular virtual

O Android Studio traz as ferramentas do Android e o **emulador** (um celular Android que roda
dentro do computador).

### 5.1 Instalar

1. Entre em <https://developer.android.com/studio> e clique em **Download Android Studio**.
   Aceite os termos e baixe.
2. Abra o instalador e clique em **Next** em tudo, sem mudar nada. No fim, **Finish**.
3. O Android Studio abre sozinho. Vai aparecer um assistente (**Setup Wizard**):
   - Se perguntar sobre importar configurações, escolha **Do not import settings**.
   - Em **Install Type**, escolha **Standard**.
   - Nas telas de licença (**License Agreement**), clique em cada item da lista da esquerda e
     marque **Accept** em todos.
   - Clique em **Finish** e espere baixar (demora bastante).

### 5.2 Instalar duas ferramentas extras

1. Na tela inicial do Android Studio ("Welcome to Android Studio"), clique em
   **More Actions** > **SDK Manager**.
2. Clique na aba **SDK Tools**.
3. No canto de baixo à direita, marque **Show Package Details**.
4. Marque:
   - **Android SDK Command-line Tools (latest)**
   - Dentro de **NDK (Side by side)**, marque a versão **28.2.13676358**
5. Clique em **Apply**, depois em **OK**, aceite a licença e espere terminar. Clique em **Finish**.

### 5.3 Criar o celular virtual (emulador)

1. Na tela inicial, clique em **More Actions** > **Virtual Device Manager**.
2. Clique no **+** (Create Virtual Device).
3. Escolha **Pixel 8** e clique em **Next**.
4. Na lista de sistemas, escolha **API 35** (Android 15). Se tiver um ícone de download ao lado,
   clique nele e espere baixar. Depois **Next**.
5. Clique em **Finish**.

### 5.4 Aceitar as licenças pelo terminal

No Prompt de Comando:

```
flutter doctor --android-licenses
```

Vai perguntar várias vezes `Accept? (y/N)`. Digite `y` e Enter em todas.
Se aparecer "All SDK package licenses accepted", está certo.

**Confira:** no Virtual Device Manager aparece o **Pixel 8** na lista.

---

## Parte 6 - Conferir se está tudo certo (flutter doctor)

```
flutter doctor
```

**Confira:** precisa aparecer **[√]** (certinho) pelo menos nestas duas linhas:

```
[√] Flutter (Channel stable, 3.47.6, ...)
[√] Android toolchain - develop for Android devices
```

Pode **ignorar** se aparecer [X] ou [!] em **Chrome** ou em **Visual Studio**. A gente não usa.

Se aparecer [X] em Flutter ou Android toolchain, veja a [Parte 13](#parte-13---deu-erro-problemas-comuns).

---

## Parte 7 - Baixar o projeto

Faça isso **uma vez só**. Vamos colocar o projeto na Área de Trabalho.

1. No Prompt de Comando, vá para a Área de Trabalho:

   ```
   cd %USERPROFILE%\Desktop
   ```

2. Baixe o projeto do GitHub:

   ```
   git clone https://github.com/GrazieliPiekas/NoBolso-PI6.git
   ```

3. Entre na pasta do projeto:

   ```
   cd NoBolso-PI6
   ```

4. Baixe as bibliotecas que o projeto usa:

   ```
   flutter pub get
   ```

**Confira:** apareceu uma pasta **NoBolso-PI6** na sua Área de Trabalho, e o `flutter pub get`
terminou com **Got dependencies!**

> Importante: daqui para frente, **todo comando de Flutter ou Git do projeto** tem que ser
> rodado **dentro da pasta do projeto**. Toda vez que abrir um terminal novo, entre nela com:
>
> ```
> cd %USERPROFILE%\Desktop\NoBolso-PI6
> ```
>
> Você sabe que está no lugar certo quando o terminal mostra algo terminando em `\NoBolso-PI6>`.

---

## Parte 8 - Rodar o app

1. **Ligue o emulador.** Duas formas, escolha uma:
   - Pelo Android Studio: **More Actions** > **Virtual Device Manager** > clique no **▶**
     ao lado do **Pixel 8**.
   - Pelo terminal:

     ```
     flutter emulators --launch Pixel_8
     ```

2. **Espere o Android do emulador ligar** por completo (aparece a tela inicial do celular).
   Na primeira vez pode levar 2 ou 3 minutos.

3. No terminal, **dentro da pasta do projeto**, rode:

   ```
   flutter run
   ```

4. A **primeira vez demora** (de 3 a 10 minutos). Aparecem várias mensagens; é normal.
   Quando terminar, o NoBolso abre sozinho no emulador.

**Confira:** no emulador aparece a tela verde do NoBolso com "Como podemos te chamar?".
Na primeira vez, depois dessa tela, aparece o tutorial (a tela escurece e um balão explica os
botões).

**Com o `flutter run` aberto, você pode apertar no terminal:**

| Tecla | O que faz |
|---|---|
| `r` | Recarrega o app na hora com as mudanças que você fez no código |
| `R` | Reinicia o app do zero |
| `q` | Fecha o app e para o `flutter run` |

**Para ver o tutorial de novo:** dentro do app, toque no menu (as três linhas no canto de
cima) e depois em **Ver tutorial de novo**.

---

## Parte 9 - Editor para ler e mexer no código (VS Code)

Para **rodar** o app só o terminal já basta. Para **ler e editar** o código, use o **VS Code**.

> **Não use o Visual Studio** (o de ícone roxo). Ele é de C#/C++ e não roda Flutter. Se ele
> perguntar sobre "CMake", clique em **Não habilitar** e feche.

1. Baixe em <https://code.visualstudio.com> e instale (Next em tudo).
2. Abra o VS Code. Clique no ícone de quadradinhos na barra da esquerda (**Extensions**).
3. Procure e instale **Flutter** (ela instala junto a extensão **Dart**).
4. Vá em **File** > **Open Folder** e escolha a pasta **NoBolso-PI6** da Área de Trabalho.
   Se perguntar se confia nos autores, clique em **Yes, I trust the authors**.

**Rodar pelo VS Code (opcional):** com o emulador ligado, olhe no canto de baixo à direita e
escolha o **Pixel 8**. Depois aperte **F5**.

**Onde está cada coisa no código:**

| Pasta | O que tem |
|---|---|
| `lib/views/` | as telas |
| `lib/viewmodels/` | a lógica de cada tela (MVVM) |
| `lib/models/` | as classes de dados |
| `lib/database/` | o banco SQLite e os DAOs (todo o SQL) |
| `lib/services/` | regras: orçamento, gráficos, PDF, planilha |
| `test/` | testes automáticos |

---

## Parte 10 - Trabalhando em grupo com o Git

**Regra de ouro:** sempre **baixe o que os outros fizeram antes de começar** e **envie o que
você fez quando terminar**. E combinem no grupo **quem mexe em qual arquivo**, para dois não
mexerem no mesmo ao mesmo tempo.

### Antes de começar a mexer (todo dia)

Dentro da pasta do projeto:

```
git pull
```

Se aparecer "Already up to date", não tinha nada novo. Se baixou coisa nova, rode também:

```
flutter pub get
```

### Depois de mexer: salvar e enviar

1. Ver o que você mudou:

   ```
   git status
   ```

2. Preparar todas as mudanças:

   ```
   git add -A
   ```

3. Salvar com uma descrição curta do que você fez (troque o texto entre aspas):

   ```
   git commit -m "Ajusta texto da tela de relatórios"
   ```

4. Enviar para o GitHub:

   ```
   git push
   ```

   **Na primeira vez**, vai abrir uma janela do navegador pedindo para entrar no GitHub.
   Clique em **Sign in with your browser**, faça login e autorize. Nas próximas vezes não pede mais.

### Se o `git push` recusar

Se aparecer algo com **"rejected"** e **"fetch first"**, é porque alguém enviou coisa nova
antes de você. Resolva assim:

```
git pull
```

```
git push
```

Se o `git pull` falar em **"CONFLICT"**, é porque você e outra pessoa mexeram na mesma parte do
mesmo arquivo. Não entre em pânico: **não apague nada** e chame a Grazieli (ou abra o arquivo no
VS Code, que mostra os dois lados e deixa escolher qual manter).

### Coisas que você NÃO deve fazer

- Não rode `git push --force`.
- Não apague a pasta do projeto para "resolver" problema sem antes enviar o que você fez.
- Não envie a pasta `build` nem arquivos do seu computador. (O projeto já está configurado
  para ignorar essas pastas, então o `git add -A` não pega elas.)

---

## Parte 11 - Rodar no seu celular de verdade (opcional)

Só funciona em celular **Android**.

### Jeito 1: com cabo USB

1. No celular, vá em **Configurações** > **Sobre o telefone** e toque **7 vezes** em
   **Número da versão** (ou "Versão do software"). Vai aparecer "Você agora é um desenvolvedor".
2. Volte e entre em **Opções do desenvolvedor** (em alguns celulares fica em **Sistema**).
3. Ligue **Depuração USB**.
4. Ligue o celular no computador com o cabo. No celular, aceite **Permitir depuração USB**.
5. No terminal, confira se o celular aparece:

   ```
   flutter devices
   ```

6. Rode o app (com o emulador **desligado**, para ele escolher o celular):

   ```
   flutter run
   ```

### Jeito 2: instalar o arquivo do app (APK)

1. Gere o arquivo:

   ```
   flutter build apk --release
   ```

2. O arquivo fica em `build\app\outputs\flutter-apk\app-release.apk`.
3. Mande esse arquivo para o celular (WhatsApp, Google Drive, cabo...) e abra. O Android vai
   pedir para permitir instalar apps de fontes desconhecidas; permita só para esse app.

---

## Parte 12 - Comandos úteis

Todos rodados **dentro da pasta do projeto**.

| Comando | Para que serve |
|---|---|
| `flutter run` | Abre o app no emulador ou celular |
| `flutter test` | Roda os testes automáticos (tem que aparecer "All tests passed!") |
| `flutter test tool/capturar_telas_test.dart` | Gera imagens de todas as telas em `build\telas\` (bom para o PDF de entrega) |
| `flutter test tool/medir_desempenho_test.dart` | Mede o tempo do banco com 100, 1.000 e 10.000 lançamentos |
| `flutter analyze` | Procura erros no código (tem que aparecer "No issues found!") |
| `flutter clean` | Apaga os arquivos gerados. Use quando der erro estranho no build; depois rode `flutter pub get` |
| `flutter build apk --release` | Gera o arquivo para instalar no celular |
| `git pull` | Baixa o que os outros enviaram |
| `git status` | Mostra o que você mudou |
| `git log --oneline -5` | Mostra os 5 últimos envios |

**Dados de teste dentro do app:** toque no círculo do perfil (canto de cima à direita do
Início). Quando o app roda pelo `flutter run`, aparecem os botões **+100**, **+1000**,
**+10000** (cria lançamentos fictícios) e **Apagar lançamentos**.

---

## Parte 13 - Deu erro? Problemas comuns

| O que aparece | O que fazer |
|---|---|
| `'flutter' não é reconhecido como um comando interno` | Feche **todos** os terminais e abra um novo. Se continuar, refaça o passo 4 da [Parte 3](#parte-3---instalar-o-flutter). |
| `'git' não é reconhecido como um comando interno` | Feche e abra o terminal. Se continuar, reinstale o Git ([Parte 2](#parte-2---instalar-o-git)). |
| `Building with plugins requires symlink support` | Ligue o Modo de Desenvolvedor ([Parte 4](#parte-4---ligar-o-modo-de-desenvolvedor-do-windows)). |
| `Android sdkmanager not found` ou `cmdline-tools component is missing` | Instale o **Android SDK Command-line Tools** (Parte 5.2). |
| Erro falando de **NDK** | Instale o **NDK 28.2.13676358** (Parte 5.2). |
| `Android license status unknown` | Rode `flutter doctor --android-licenses` e responda `y` em tudo. |
| `No devices found` ou `No supported devices connected` | O emulador não está ligado. Ligue ([Parte 8](#parte-8---rodar-o-app)) e espere ele terminar de abrir. |
| O emulador não abre ou fala em **virtualization** / **hypervisor** | A virtualização do computador está desligada. No Android Studio: **More Actions** > **SDK Manager** > **SDK Tools** > instale **Android Emulator hypervisor driver**. Se ainda assim não abrir, precisa ligar "Virtualization" / "VT-x" / "SVM" na BIOS do computador (peça ajuda, varia por marca). |
| Emulador muito lento | Feche outros programas pesados (Chrome com muitas abas, jogos). Com 8 GB de RAM ele fica lento mesmo. |
| `Could not find a file named "pubspec.yaml"` | Você não está dentro da pasta do projeto. Rode `cd %USERPROFILE%\Desktop\NoBolso-PI6`. |
| `Gradle task assembleDebug failed` (primeira vez) | Rode `flutter clean`, depois `flutter pub get` e tente `flutter run` de novo. Confira também se a internet está boa. |
| `Author identity unknown` ao fazer commit | Faltou configurar nome e e-mail (passo 5 da [Parte 2](#parte-2---instalar-o-git)). |
| `Permission denied` ou `403` no `git push` | Você ainda não aceitou o convite do repositório ([Parte 1](#parte-1---conta-no-github-e-convite)), ou entrou com outra conta do GitHub. |
| `rejected ... fetch first` no `git push` | Rode `git pull` e depois `git push` de novo (Parte 10). |
| O teclado do emulador mostra "Try out your stylus" | É do teclado do Android, não do app. Toque em **Cancel**. |
| O app fica um tempo na tela verde com o logo | Normal na primeira vez no modo de desenvolvimento. Espere uns 20 segundos. |
| O tutorial não aparece | Ele só aparece no primeiro acesso. Use **menu > Ver tutorial de novo**, ou desinstale o app do emulador (segure o ícone e arraste para "Desinstalar") e rode `flutter run` de novo. |

Se nada disso resolver: **tire um print do terminal inteiro** (com a mensagem de erro) e mande
no grupo.

---

## Checklist final

Marque cada item. Se todos estiverem certos, você está pronto.

- [ ] Tenho conta no GitHub e **aceitei o convite** do repositório.
- [ ] `git --version` mostra a versão do Git.
- [ ] Configurei `user.name` e `user.email` no Git.
- [ ] `flutter --version` mostra **3.47.6**.
- [ ] O **Modo de Desenvolvedor** do Windows está ativado.
- [ ] Instalei o Android Studio, o **Command-line Tools** e o **NDK 28.2.13676358**.
- [ ] Criei o emulador **Pixel 8** com **API 35**.
- [ ] `flutter doctor` mostra [√] em **Flutter** e em **Android toolchain**.
- [ ] Baixei o projeto com `git clone` e rodei `flutter pub get`.
- [ ] `flutter run` abriu o NoBolso no emulador.
- [ ] `flutter test` mostrou **All tests passed!**
- [ ] Sei fazer `git pull` antes de começar e `git add -A`, `git commit` e `git push` depois.
