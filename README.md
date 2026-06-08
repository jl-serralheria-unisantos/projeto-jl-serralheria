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
flutter run
```

## Firebase

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

## Divisão da equipe

| Área | Responsabilidade |
|---|---|
| Integração/base | Revisar PRs, manter a develop estável e resolver conflitos |
| Clientes | Cadastro, edição, listagem e exclusão de clientes |
| Produtos e serviços | Cadastro, edição, listagem e exclusão de produtos e serviços |
| Orçamentos | Criação, edição, listagem, detalhes e status dos orçamentos |
| PDF/documentação | Geração de PDF, testes, prints, README e relatório |

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
flutter build apk
```

O APK será gerado normalmente em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Para gerar APKs separados por arquitetura:

```bash
flutter build apk --split-per-abi
```
## Status atual

O projeto está na fase de integração final das funcionalidades principais:

- Cadastros principais encaminhados
- Orçamentos implementados
- PDF integrado ao detalhe do orçamento
- Documentação em atualização
- Testes manuais pendentes para validação final
