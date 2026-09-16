/// Modelos de dados da aplicacao.
/// Cada modelo converte directamente de/para as linhas da base de dados.

class Empresa {
  final int id;
  final String nome;
  final String? nif;
  final String? endereco;
  final String? telefone;
  final String? email;
  final String moeda;
  final String criadoEm;

  const Empresa({
    required this.id,
    required this.nome,
    this.nif,
    this.endereco,
    this.telefone,
    this.email,
    required this.moeda,
    required this.criadoEm,
  });

  factory Empresa.fromMap(Map<String, Object?> m) => Empresa(
        id: m['id'] as int,
        nome: m['nome'] as String,
        nif: m['nif'] as String?,
        endereco: m['endereco'] as String?,
        telefone: m['telefone'] as String?,
        email: m['email'] as String?,
        moeda: (m['moeda'] as String?) ?? 'AOA',
        criadoEm: m['criado_em'] as String,
      );
}

class Usuario {
  final int id;
  final String nome;
  final String username;
  final String perfil; // admin | operador
  final bool ativo;
  final String criadoEm;

  const Usuario({
    required this.id,
    required this.nome,
    required this.username,
    required this.perfil,
    required this.ativo,
    required this.criadoEm,
  });

  bool get isAdmin => perfil == 'admin';

  factory Usuario.fromMap(Map<String, Object?> m) => Usuario(
        id: m['id'] as int,
        nome: m['nome'] as String,
        username: m['username'] as String,
        perfil: (m['perfil'] as String?) ?? 'operador',
        ativo: ((m['ativo'] as int?) ?? 1) == 1,
        criadoEm: m['criado_em'] as String,
      );
}

class Funcionario {
  final int? id;
  final String codigo;
  final String nome;
  final String? bi;
  final String? dataNascimento;
  final String? genero;
  final String? telefone;
  final String? email;
  final String? endereco;
  final String? cargo;
  final String? departamento;
  final String? dataAdmissao;
  final String? dataSaida;
  final double salarioBase;
  final String? iban;
  final String? segurancaSocial;
  final String estado; // activo | suspenso | inactivo
  final String? observacoes;

  const Funcionario({
    this.id,
    required this.codigo,
    required this.nome,
    this.bi,
    this.dataNascimento,
    this.genero,
    this.telefone,
    this.email,
    this.endereco,
    this.cargo,
    this.departamento,
    this.dataAdmissao,
    this.dataSaida,
    this.salarioBase = 0,
    this.iban,
    this.segurancaSocial,
    this.estado = 'activo',
    this.observacoes,
  });

  factory Funcionario.fromMap(Map<String, Object?> m) => Funcionario(
        id: m['id'] as int?,
        codigo: m['codigo'] as String,
        nome: m['nome'] as String,
        bi: m['bi'] as String?,
        dataNascimento: m['data_nascimento'] as String?,
        genero: m['genero'] as String?,
        telefone: m['telefone'] as String?,
        email: m['email'] as String?,
        endereco: m['endereco'] as String?,
        cargo: m['cargo'] as String?,
        departamento: m['departamento'] as String?,
        dataAdmissao: m['data_admissao'] as String?,
        dataSaida: m['data_saida'] as String?,
        salarioBase: ((m['salario_base'] as num?) ?? 0).toDouble(),
        iban: m['iban'] as String?,
        segurancaSocial: m['seguranca_social'] as String?,
        estado: (m['estado'] as String?) ?? 'activo',
        observacoes: m['observacoes'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'codigo': codigo,
        'nome': nome,
        'bi': bi,
        'data_nascimento': dataNascimento,
        'genero': genero,
        'telefone': telefone,
        'email': email,
        'endereco': endereco,
        'cargo': cargo,
        'departamento': departamento,
        'data_admissao': dataAdmissao,
        'data_saida': dataSaida,
        'salario_base': salarioBase,
        'iban': iban,
        'seguranca_social': segurancaSocial,
        'estado': estado,
        'observacoes': observacoes,
      };

  Funcionario copyWith({
    int? id,
    String? codigo,
    String? nome,
    String? bi,
    String? dataNascimento,
    String? genero,
    String? telefone,
    String? email,
    String? endereco,
    String? cargo,
    String? departamento,
    String? dataAdmissao,
    String? dataSaida,
    double? salarioBase,
    String? iban,
    String? segurancaSocial,
    String? estado,
    String? observacoes,
  }) {
    return Funcionario(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      bi: bi ?? this.bi,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      genero: genero ?? this.genero,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      endereco: endereco ?? this.endereco,
      cargo: cargo ?? this.cargo,
      departamento: departamento ?? this.departamento,
      dataAdmissao: dataAdmissao ?? this.dataAdmissao,
      dataSaida: dataSaida ?? this.dataSaida,
      salarioBase: salarioBase ?? this.salarioBase,
      iban: iban ?? this.iban,
      segurancaSocial: segurancaSocial ?? this.segurancaSocial,
      estado: estado ?? this.estado,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

class Documento {
  final int? id;
  final int funcionarioId;
  final String tipo;
  final String titulo;
  final String ficheiroNome;
  final String caminho;
  final String? dataEmissao;
  final String? dataValidade;
  final String? observacao;
  final String? criadoEm;

  const Documento({
    this.id,
    required this.funcionarioId,
    required this.tipo,
    required this.titulo,
    required this.ficheiroNome,
    required this.caminho,
    this.dataEmissao,
    this.dataValidade,
    this.observacao,
    this.criadoEm,
  });

  factory Documento.fromMap(Map<String, Object?> m) => Documento(
        id: m['id'] as int?,
        funcionarioId: m['funcionario_id'] as int,
        tipo: m['tipo'] as String,
        titulo: m['titulo'] as String,
        ficheiroNome: m['ficheiro_nome'] as String,
        caminho: m['caminho'] as String,
        dataEmissao: m['data_emissao'] as String?,
        dataValidade: m['data_validade'] as String?,
        observacao: m['observacao'] as String?,
        criadoEm: m['criado_em'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'funcionario_id': funcionarioId,
        'tipo': tipo,
        'titulo': titulo,
        'ficheiro_nome': ficheiroNome,
        'caminho': caminho,
        'data_emissao': dataEmissao,
        'data_validade': dataValidade,
        'observacao': observacao,
      };
}

/// Estados possiveis de presenca num dia.
class EstadoPresenca {
  static const String presente = 'presente';
  static const String falta = 'falta';
  static const String justificada = 'justificada';
  static const String atraso = 'atraso';
  static const String ferias = 'ferias';
  static const String folga = 'folga';

  static const List<String> todos = [
    presente,
    falta,
    justificada,
    atraso,
    ferias,
    folga,
  ];

  static String rotulo(String e) {
    switch (e) {
      case presente:
        return 'Presente';
      case falta:
        return 'Falta';
      case justificada:
        return 'Falta justificada';
      case atraso:
        return 'Atraso';
      case ferias:
        return 'Ferias';
      case folga:
        return 'Folga';
      default:
        return e;
    }
  }

  static String sigla(String e) {
    switch (e) {
      case presente:
        return 'P';
      case falta:
        return 'F';
      case justificada:
        return 'J';
      case atraso:
        return 'A';
      case ferias:
        return 'V';
      case folga:
        return 'D';
      default:
        return '-';
    }
  }
}

class Presenca {
  final int? id;
  final int funcionarioId;
  final String data; // YYYY-MM-DD
  final String estado;
  final double horas;
  final String? observacao;

  const Presenca({
    this.id,
    required this.funcionarioId,
    required this.data,
    required this.estado,
    this.horas = 0,
    this.observacao,
  });

  factory Presenca.fromMap(Map<String, Object?> m) => Presenca(
        id: m['id'] as int?,
        funcionarioId: m['funcionario_id'] as int,
        data: m['data'] as String,
        estado: m['estado'] as String,
        horas: ((m['horas'] as num?) ?? 0).toDouble(),
        observacao: m['observacao'] as String?,
      );
}

class Pagamento {
  final int? id;
  final int funcionarioId;
  final int ano;
  final int mes;
  final double salarioBase;
  final double subsidios;
  final double bonus;
  final double horasExtra;
  final double descontoFaltas;
  final double adiantamentos;
  final double outrosDescontos;
  final double liquido;
  final String estado; // pendente | pago
  final String? metodo;
  final String? dataPagamento;
  final String? observacao;

  const Pagamento({
    this.id,
    required this.funcionarioId,
    required this.ano,
    required this.mes,
    this.salarioBase = 0,
    this.subsidios = 0,
    this.bonus = 0,
    this.horasExtra = 0,
    this.descontoFaltas = 0,
    this.adiantamentos = 0,
    this.outrosDescontos = 0,
    this.liquido = 0,
    this.estado = 'pendente',
    this.metodo,
    this.dataPagamento,
    this.observacao,
  });

  double get totalGanhos => salarioBase + subsidios + bonus + horasExtra;

  double get totalDescontos =>
      descontoFaltas + adiantamentos + outrosDescontos;

  double get calculado => totalGanhos - totalDescontos;

  factory Pagamento.fromMap(Map<String, Object?> m) => Pagamento(
        id: m['id'] as int?,
        funcionarioId: m['funcionario_id'] as int,
        ano: m['ano'] as int,
        mes: m['mes'] as int,
        salarioBase: ((m['salario_base'] as num?) ?? 0).toDouble(),
        subsidios: ((m['subsidios'] as num?) ?? 0).toDouble(),
        bonus: ((m['bonus'] as num?) ?? 0).toDouble(),
        horasExtra: ((m['horas_extra'] as num?) ?? 0).toDouble(),
        descontoFaltas: ((m['desconto_faltas'] as num?) ?? 0).toDouble(),
        adiantamentos: ((m['adiantamentos'] as num?) ?? 0).toDouble(),
        outrosDescontos: ((m['outros_descontos'] as num?) ?? 0).toDouble(),
        liquido: ((m['liquido'] as num?) ?? 0).toDouble(),
        estado: (m['estado'] as String?) ?? 'pendente',
        metodo: m['metodo'] as String?,
        dataPagamento: m['data_pagamento'] as String?,
        observacao: m['observacao'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'funcionario_id': funcionarioId,
        'ano': ano,
        'mes': mes,
        'salario_base': salarioBase,
        'subsidios': subsidios,
        'bonus': bonus,
        'horas_extra': horasExtra,
        'desconto_faltas': descontoFaltas,
        'adiantamentos': adiantamentos,
        'outros_descontos': outrosDescontos,
        'liquido': liquido,
        'estado': estado,
        'metodo': metodo,
        'data_pagamento': dataPagamento,
        'observacao': observacao,
      };

  Pagamento copyWith({
    int? id,
    double? salarioBase,
    double? subsidios,
    double? bonus,
    double? horasExtra,
    double? descontoFaltas,
    double? adiantamentos,
    double? outrosDescontos,
    double? liquido,
    String? estado,
    String? metodo,
    String? dataPagamento,
    String? observacao,
  }) {
    return Pagamento(
      id: id ?? this.id,
      funcionarioId: funcionarioId,
      ano: ano,
      mes: mes,
      salarioBase: salarioBase ?? this.salarioBase,
      subsidios: subsidios ?? this.subsidios,
      bonus: bonus ?? this.bonus,
      horasExtra: horasExtra ?? this.horasExtra,
      descontoFaltas: descontoFaltas ?? this.descontoFaltas,
      adiantamentos: adiantamentos ?? this.adiantamentos,
      outrosDescontos: outrosDescontos ?? this.outrosDescontos,
      liquido: liquido ?? this.liquido,
      estado: estado ?? this.estado,
      metodo: metodo ?? this.metodo,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      observacao: observacao ?? this.observacao,
    );
  }
}

/// Linha combinada usada nos ecras de presencas e pagamentos.
class FuncionarioResumo {
  final Funcionario funcionario;
  final int presentes;
  final int faltas;
  final int justificadas;
  final int atrasos;

  const FuncionarioResumo({
    required this.funcionario,
    this.presentes = 0,
    this.faltas = 0,
    this.justificadas = 0,
    this.atrasos = 0,
  });
}
