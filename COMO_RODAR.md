# Como rodar o NoBolso

Guia em duas partes:

- **Parte 1** – para quem já tem tudo instalado (o PC da Grazieli).
- **Parte 2** – para configurar um PC do zero (Erick e Gustavo).

Os comandos são para o **Prompt de Comando (cmd)** ou o **PowerShell** do Windows.

---

## Parte 1 – Rodar de novo (PC já configurado)

1. Abra o **Android Studio** → **More Actions** → **Virtual Device Manager** e clique no ▶ do **Pixel 8**.
   (Ou pelo terminal: `flutter emulators --launch Pixel_8`.)
2. Espere o Android do emulador aparecer na tela.
3. No terminal, entre na pasta do projeto:
   ```
   cd C:\Users\Grazieli\Desktop\2026.2\PI6\Projeto
   ```
4. Baixe as alterações dos colegas (se houver):
   ```
   git pull
   ```
5. Rode o app:
   ```
   flutter run
   ```

Com o `flutter run` aberto:

| Tecla | O que faz |
|-------|-----------|
| `r` | Recarrega o app na hora com as mudanças do código (hot reload) |
| `R` | Reinicia o app do zero |
| `q` | Fecha |

A primeira execução do dia pode demorar alguns minutos. Isso é normal.

---

## Parte 2 – Configurar um PC do zero

Faça uma vez só, na ordem. Leva uns 40 minutos, quase tudo é download.

### 2.1 Git

Baixe e instale em <https://git-scm.com/download/win> (pode deixar tudo no padrão).
Depois, no terminal, configure seu nome e e-mail (os mesmos do GitHub):
```
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"
```

### 2.2 Flutter

1. Crie o Flutter em `C:\src\flutter`:
   ```
   mkdir C:\src
   git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
   ```
2. Coloque o Flutter no PATH. No **PowerShell**, rode:
   ```
   [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ';C:\src\flutter\bin', 'User')
   ```
3. **Feche e abra o terminal de novo** e teste:
   ```
   flutter --version
   ```
   O projeto foi feito com o Flutter **3.47.6**. Uma versão mais nova do canal stable também deve funcionar.

### 2.3 Modo de Desenvolvedor do Windows

**Configurações → Sistema → Para desenvolvedores → Modo de Desenvolvedor: Ativado.**
Sem isso, o build falha com o erro *"Building with plugins requires symlink support"*.

### 2.4 Android Studio

1. Baixe e instale em <https://developer.android.com/studio>.
2. Abra uma vez e siga o assistente inicial (ele baixa o Android SDK). Aceite as licenças.
3. Na tela inicial: **More Actions → SDK Manager → aba SDK Tools**. Marque **Show Package Details** (canto inferior direito) e instale:
   - **Android SDK Command-line Tools (latest)**
   - **NDK (Side by side)** → versão **28.2.13676358**

   Clique em **Apply** e aceite as licenças.
4. Crie o emulador: **More Actions → Virtual Device Manager → +**, escolha **Pixel 8**, depois a imagem **API 35** e clique em **Finish**.
5. No terminal, aceite as licenças restantes, respondendo `y` a cada pergunta:
   ```
   flutter doctor --android-licenses
   ```
   Se aparecer *"The --licenses option is no longer needed"*, está tudo certo.

### 2.5 Conferir

```
flutter doctor
```
Precisa aparecer **✓** em *Flutter* e em *Android toolchain*. Os itens de Chrome e Visual Studio não são necessários.

### 2.6 Baixar e rodar o projeto

```
cd C:\Users\SEU_USUARIO\Desktop
git clone https://github.com/GrazieliPiekas/NoBolso-PI6.git
cd NoBolso-PI6
flutter pub get
```
Ligue o emulador (passo 1 da Parte 1) e rode:
```
flutter run
```

---

## Trabalhando em grupo com o Git

Para conseguir **enviar** alterações, a Grazieli precisa adicionar cada colega como colaborador em
**GitHub → repositório NoBolso-PI6 → Settings → Collaborators → Add people**. O colega aceita o convite que chega por e-mail.

Rotina sugerida:

```
git pull                      # antes de começar: baixa o que os outros fizeram
git add -A                    # depois de mexer: prepara as alterações
git commit -m "o que mudou"   # salva com uma descrição
git push                      # envia para o GitHub
```

Combinem quem mexe em qual arquivo para evitar conflitos.

---

## Comandos úteis

| Comando | Para quê |
|---------|----------|
| `flutter test` | Roda os 38 testes automatizados |
| `flutter test tool/capturar_telas_test.dart` | Gera imagens das telas em `build/telas/` |
| `flutter test tool/medir_desempenho_test.dart` | Mede tempos com 100, 1.000 e 10.000 lançamentos |
| `flutter analyze` | Procura erros no código |
| `flutter build apk --release` | Gera o APK em `build/app/outputs/flutter-apk/` para instalar num celular |

**Dados fictícios para testes:** no app, toque no círculo do perfil (canto superior direito do Início). Em modo debug aparecem os botões **+100**, **+1000**, **+10000** e **Apagar lançamentos**.

---

## Problemas comuns

| Problema | Solução |
|----------|---------|
| `'flutter' não é reconhecido como um comando` | Feche e abra o terminal. Se continuar, refaça o passo 2.2. |
| `Building with plugins requires symlink support` | Ative o Modo de Desenvolvedor (passo 2.3). |
| `Android sdkmanager not found` | Instale o **Command-line Tools** (passo 2.4, item 3). |
| `NDK ... did not install` ou erro com `ndk` | Instale o **NDK 28.2.13676358** (passo 2.4, item 3). |
| `No devices found` / `No supported devices connected` | O emulador não está ligado. Ligue antes do `flutter run`. |
| Teclado do emulador abre "Try out your stylus" | É do teclado Gboard, não do app. Toque em **Cancel**. |
| O app fica muito tempo na tela branca com o logo | Normal na primeira execução em modo debug. Espere uns 20 segundos. |
