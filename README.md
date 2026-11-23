# Projeto JL Serralheria - Aplicativo Flutter

Aplicativo mobile desenvolvido em Flutter para apoiar a rotina de uma serralheria no cadastro de clientes, produtos, serviços e geração de orçamentos.

O sistema permite montar orçamentos com produtos, serviços e itens manuais, calcular subtotal, desconto e valor final, além de gerar e compartilhar o PDF do orçamento.

## Tecnologias utilizadas

- Flutter
- Dart
- Firebase
- Cloud Firestore
- PDF/Printing
- Intl
- Git/GitHub

## Funcionalidades

- Cadastro, edição, listagem e exclusão de clientes
- Cadastro, edição, listagem e exclusão de produtos
- Cadastro, edição, listagem e exclusão de serviços
- Criação de orçamento
- Seleção de cliente no orçamento
- Adição de produtos ao orçamento
- Adição de serviços ao orçamento
- Adição de itens manuais ao orçamento
- Cálculo de subtotal
- Aplicação de desconto
- Cálculo do valor final
- Listagem de orçamentos
- Detalhamento de orçamento
- Alteração de status do orçamento
- Geração de PDF do orçamento
- Compartilhamento do PDF

## Estrutura principal

```text
lib/
  app.dart
  app_state.dart
  main.dart
  firebase_options.dart

  data/
    models/
    repositories/

  features/
    clientes/
    produtos/
    servicos/
    orcamentos/
    pdf/

  shared/
    formatters.dart
```

## Como executar o projeto

Clone o repositório:

```bash
git clone https://github.com/jl-serralheria-unisantos/projeto-jl-serralheria.git
cd projeto-jl-serralheria
```

Entre na branch de desenvolvimento:

```bash
git checkout develop
git pull
```

Instale as dependências:

```bash
flutter pub get
```

Execute o projeto:

```bash
flutter run --dart-define-from-file=.env.owner.json
```

## Firebase

### Configuração do proprietário

1. No projeto correto do Firebase, habilite o provedor **E-mail/senha** em Authentication. Em **Users**, crie a conta do proprietário pelo console ou selecione a conta existente. Copie o UID atribuído pelo Firebase. Use as credenciais apenas no login.
2. Para impedir cadastro direto pela API, desative a criação de contas pelos usuários finais em **Authentication → Settings → User actions**. Caso essa opção exija Identity Platform no seu projeto, verifique disponibilidade e custo antes de habilitá-la. Enquanto o cadastro no provedor estiver aberto, outras contas poderão existir no Auth, mas as regras abaixo bloqueiam o acesso delas aos dados. [Documentação de cadastro pelo administrador](https://docs.cloud.google.com/identity-platform/docs/concepts-manage-users)
3. Crie `.env.owner.json` com o conteúdo `{"OWNER_UID":"UID_COPIADO_DO_CONSOLE"}` usando o UID real. Este arquivo identifica a conta. A senha pertence ao login. Use o mesmo JSON na validação e em `flutter run`, `flutter build web` e `flutter build apk` com `--dart-define-from-file=.env.owner.json`. O template `firestore.rules` do repositório deve permanecer com UID vazio.
4. Prepare o candidato em um caminho novo. Os comandos abaixo usam Node.js 22, Java 21 ou superior e somente os emuladores locais. O provisionamento das contas de teste ocorre no projeto fictício `demo-jl-serralheria`.

```sh
node scripts/prepare-firestore.mjs .env.owner.json build/ativacao/candidato.rules
npx --yes firebase-tools@14.27.0 emulators:exec --only "auth,firestore" --project demo-jl-serralheria "node scripts/test-firestore.mjs build/ativacao/candidato.rules .env.owner.json"
```

O primeiro comando gera um arquivo separado. O segundo lê o candidato sem modificá-lo, verifica o UID contra o JSON do build e carrega o conteúdo no emulador. A suíte cobre o template fechado, os quatro cadastros e os acessos por UID, provedor e caminho. Somente após aprovação ela imprime o SHA-256 e grava `candidato.rules.sha256`. Arquive o candidato, o hash e a identificação do build juntos. Repita a validação após qualquer alteração.

Na ativação manual, confira projeto, banco e conta no console, a sincronização das últimas alterações e a assinatura do APK instalado. Coordene a atualização do aplicativo e a publicação **do candidato aprovado**. O `firebase.json` da raiz aponta ao template fechado. Depois da publicação, confira o conteúdo do ruleset da release ativa e seu SHA-256 comparando os mesmos bytes UTF-8 com o registro da validação. Verifique o acesso do proprietário por leitura. Versões antigas sem login perdem o acesso ao servidor após a propagação. A transição preserva os documentos e dispensa migração. Para recuperação de senha, redefina a senha da mesma conta para preservar o UID.

### Sessão e acesso offline

Ao iniciar ou voltar ao primeiro plano, o aplicativo consulta o Firebase Authentication antes de mostrar dados. Enquanto verifica a conta, bloqueia as telas privadas. Falha de conexão mantém a sessão bloqueada e oferece nova tentativa. Uma validação bem-sucedida permite continuar a edição aberta. Desativação, exclusão ou credencial de sessão inválida encerram o acesso e descartam o estado privado em memória. O logout não garante exclusão física do cache do Firestore no aparelho. Uma desativação administrativa durante o uso contínuo pode ser percebida na próxima revalidação. O aplicativo não faz consultas periódicas de autenticação.

### Testar com a configuração fictícia

Para desenvolvimento, use o JSON de demonstração exclusivamente com os emuladores. Em um diretório de saída novo, execute:

```sh
node scripts/prepare-firestore.mjs scripts/emulator-owner.json build/teste/candidato.rules
npx --yes firebase-tools@14.27.0 emulators:exec --only "auth,firestore" --project demo-jl-serralheria "node scripts/test-firestore.mjs build/teste/candidato.rules scripts/emulator-owner.json"
flutter analyze
flutter test
```

O projeto utiliza Firebase e Cloud Firestore como persistência principal dos dados.

Antes de executar o aplicativo, confirme se os arquivos de configuração do Firebase estão corretamente presentes no projeto, como:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Caso o projeto seja clonado em uma nova máquina e haja erro de Firebase, verifique a configuração pelo Firebase CLI ou pelo FlutterFire CLI.

## Fluxo de branches

Branches principais:

- `main`: versão final e estável
- `develop`: branch de integração
- `feature/*`: branches de desenvolvimento de funcionalidades

Exemplos:

```text
feature/clientes
feature/produtos-servicos
feature/orcamentos
feature/pdf-documentacao
feature/pdf-orcamento
```

## Como iniciar uma tarefa

Antes de começar qualquer tarefa:

```bash
git checkout develop
git pull
git checkout -b feature/nome-da-tarefa
```

Exemplo:

```bash
git checkout develop
git pull
git checkout -b feature/pdf-orcamento
```

## Antes de abrir Pull Request

Execute:

```bash
flutter analyze
flutter test
```

Depois faça commit e push:

```bash
git add .
git commit -m "Descreve a alteração realizada"
git push -u origin feature/nome-da-tarefa
```

O Pull Request deve ser aberto para:

```text
feature/nome-da-tarefa -> develop
```

## Critérios de teste manual

Antes de considerar a entrega pronta, testar:

- Criar cliente
- Editar cliente
- Excluir cliente sem orçamento vinculado
- Criar produto
- Editar produto
- Excluir produto
- Criar serviço
- Editar serviço
- Excluir serviço
- Criar orçamento
- Selecionar cliente
- Adicionar produto ao orçamento
- Adicionar serviço ao orçamento
- Adicionar item manual
- Aplicar desconto
- Salvar orçamento
- Abrir detalhe do orçamento
- Alterar status do orçamento
- Visualizar PDF
- Compartilhar PDF

## Geração de APK para Android

Para gerar um APK de teste:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --dart-define-from-file=.env.owner.json
```

O APK será gerado normalmente em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Para gerar APKs separados por arquitetura:

```bash
flutter build apk --split-per-abi --dart-define-from-file=.env.owner.json
```
## Status atual

O projeto está na fase de integração final das funcionalidades principais:

- Cadastros principais encaminhados
- Orçamentos implementados
- PDF integrado ao detalhe do orçamento
- Documentação em atualização
- Testes manuais pendentes para validação final

## Cálculo dos orçamentos

Cada linha multiplica a quantidade pelo preço unitário em representação decimal exata e arredonda uma vez para centavos. Meio centavo arredonda para cima. O subtotal soma os centavos das linhas. O desconto pode ir de zero até o subtotal, inclusive. Por exemplo, 200 linhas de 0,125 m a R$ 1,00/m somam R$ 26,00. Uma única linha de 25 m ao mesmo preço soma R$ 25,00.

O editor aceita até nove dígitos inteiros, duas casas para dinheiro e seis para quantidades positivas de qualquer unidade, inclusive metro, área e hora. A unidade é texto livre no cadastro. A vírgula separa decimais. O agrupamento de milhares exige uma parte decimal explícita, como em `1.234,56`. Para mil unidades inteiras, digite `1000`. O subtotal máximo por orçamento é R$ 999.999.999,99.

O Firestore mantém os campos numéricos existentes. A consulta usa o total gravado. Na falta dele, o leitor conserva o cálculo histórico. Se as linhas e o desconto não conciliam com o total gravado, o aplicativo solicita revisão antes de emitir um novo PDF e confirmação ao salvar a edição. Para registros sem itens, o PDF identifica o histórico e apresenta o total registrado. Atualizações de status continuam independentes. A adoção dessa regra dispensa migração em lote.

### Registros financeiros históricos

A leitura de preços de produtos e serviços aceita números e valores históricos como `R$ 125,50`. Zero é um preço válido. Um campo ausente ou ilegível fica pendente de revisão e o editor exige um preço válido antes de salvar. Uma string monetária sem símbolo e com separador ambíguo, como `0.125`, também exige revisão. Essa compatibilidade é exclusiva da leitura dos documentos.

O orçamento compara os totais em centavos. Por exemplo, um total gravado como `0.30000000000000004` equivale a R$ 0,30 para emissão e edição. Uma alteração de observações conserva o total bruto equivalente. Quando uma edição muda o total em centavos, ou quando o orçamento já exige revisão, o editor apresenta os dois valores antes da gravação. Cancelar mantém o documento original.

O painel e a lista somam os valores conhecidos das propostas não recusadas e indicam quantos registros têm total a revisar. Um total ausente só pode ser reconstruído se houver itens com valores para o cálculo histórico. Um total explicitamente ilegível permanece pendente, mesmo quando há itens.
