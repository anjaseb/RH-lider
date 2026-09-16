# RH Lider

Aplicacao de secretaria (desktop) para gestao de funcionarios, presencas mensais,
pagamentos e documentos. Funciona sem internet: todos os dados ficam guardados
no proprio computador, numa base de dados SQLite.

## O que o sistema faz

**Funcionarios**
- Registo completo: codigo/ID automatico, nome, bilhete de identidade, data de
  nascimento, genero, contactos, endereco, cargo, departamento, datas de
  admissao e saida, salario base, IBAN, seguranca social e observacoes.
- Estados: activo, suspenso e inactivo.
- Pesquisa por nome, codigo, BI, cargo ou telefone.

**Documentos**
- Anexar contratos, BI, certificados, curriculos, atestados e outros ficheiros.
- Os ficheiros sao copiados para a pasta da aplicacao, com tipo, data de emissao
  e data de validade.
- Aviso no painel para documentos que expiram nos proximos 60 dias.

**Presencas mensais**
- Grelha do mes com funcionarios em linha e dias em coluna.
- Estados por dia: presente, falta, falta justificada, atraso, ferias e folga.
- Preenchimento automatico dos dias uteis e limpeza do mes.
- Resumo por funcionario directamente na grelha.

**Pagamentos**
- Folha mensal gerada a partir dos salarios base.
- Desconto por faltas calculado automaticamente com base nas presencas.
- Campos editaveis: subsidios, bonus, horas extra, adiantamentos e outros
  descontos, com calculo do valor liquido.
- Estado pago/pendente, metodo de pagamento e historico por funcionario.

**Acessos**
- Registo inicial da empresa com senha geral.
- Utilizador administrador criado no primeiro arranque.
- Perfis: administrador (acesso total) e operador (sem utilizadores nem
  configuracoes).
- Criacao, desactivacao, redefinicao de senha e eliminacao de utilizadores.

## Primeiro arranque

1. Abrir a aplicacao.
2. Passo 1: preencher os dados da empresa e definir a senha geral.
3. Passo 2: criar o utilizador administrador.
4. Iniciar sessao com o utilizador criado.

Guarde as credenciais. Nao ha recuperacao automatica de senha: os dados estao
apenas no computador onde a aplicacao foi instalada.

## Onde ficam os dados

Os ficheiros sao guardados em:

```
C:\Users\<utilizador>\AppData\Roaming\com.example\rh_lider\RH Lider\
```

Dentro dessa pasta:
- `rh_lider.db` - base de dados com todos os registos
- `documentos\` - copias dos ficheiros anexados aos funcionarios

O caminho exacto aparece em **Configuracoes**. Para copia de seguranca, feche a
aplicacao e copie essa pasta inteira.

## Compilar no GitHub

O repositorio inclui `.github/workflows/build-windows.yml`. Depois do push:

1. Abrir o separador **Actions** no GitHub.
2. Esperar que o fluxo **Compilar Windows** termine.
3. Descarregar o ficheiro `RH-Lider-Windows.zip` na seccao Artifacts.
4. Extrair e executar `rh_lider.exe`.

O fluxo corre `flutter create --platforms=windows .` automaticamente, por isso a
pasta `windows/` nao precisa de estar no repositorio.

## Compilar no proprio computador

Requer Flutter instalado e, no Windows, o Visual Studio com a carga de trabalho
"Desenvolvimento para desktop com C++".

```bash
flutter config --enable-windows-desktop
flutter create --platforms=windows .
flutter pub get
flutter run -d windows          # para testar
flutter build windows --release # para gerar o executavel
```

O executavel fica em `build\windows\x64\runner\Release\`.

## Estrutura do projecto

```
lib/
  main.dart                     arranque e roteamento inicial
  data/database.dart            esquema SQLite e acesso a base de dados
  models/models.dart            modelos de dados
  services/
    auth_service.dart           empresa, sessao e utilizadores
    funcionario_service.dart    funcionarios e documentos
    presenca_service.dart       folha de presencas
    pagamento_service.dart      folha de pagamentos
  screens/
    login_screen.dart
    shell_screen.dart           menu lateral e navegacao
    painel_screen.dart          indicadores gerais
    funcionarios/               lista, formulario e detalhe
    presencas/                  grelha mensal
    pagamentos/                 folha mensal
    usuarios/                   gestao de acessos
    configuracoes/              registo inicial e definicoes
  theme/app_theme.dart          cores e estilos
  utils/helpers.dart            datas, valores e senhas
  widgets/common.dart           componentes reutilizaveis
```

## Notas tecnicas

- As senhas sao guardadas com SHA-256 e salt aleatorio por utilizador, nunca em
  texto simples.
- Cada funcionario tem no maximo um registo de presenca por dia e um pagamento
  por mes, garantido pela propria base de dados.
- Eliminar um funcionario remove em cascata presencas, pagamentos e documentos.
