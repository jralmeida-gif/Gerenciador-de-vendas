import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/whatsapp.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/comuns.dart';
import 'venda_form.dart';

class TelaVendasLista extends StatefulWidget {
  const TelaVendasLista({super.key});

  @override
  State<TelaVendasLista> createState() => _TelaVendasListaState();
}

class _TelaVendasListaState extends State<TelaVendasLista> {
  final _busca = TextEditingController();
  String _filtroProduto = 'Todos';
  int _periodo = 0; // 0=hoje 1=mês 2=tudo

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  List<Venda> _filtrar(List<Venda> todas) {
    final hoje = DateTime.now();
    var l = todas;
    if (_periodo == 0) {
      l = l.where((v) => mesmoDia(v.data, hoje)).toList();
    } else if (_periodo == 1) {
      l = l
          .where((v) => v.data.year == hoje.year && v.data.month == hoje.month)
          .toList();
    }
    if (_filtroProduto != 'Todos') {
      l = l.where((v) => v.produto == _filtroProduto).toList();
    }
    final termo = _busca.text.trim().toLowerCase();
    if (termo.isNotEmpty) {
      final dig = Fmt.somenteDigitos(termo);
      l = l
          .where(
            (v) =>
                v.nome.toLowerCase().contains(termo) ||
                (dig.isNotEmpty && v.cpf.contains(dig)),
          )
          .toList();
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final lista = _filtrar(estado.vendas);
    final grupos = _agruparPorCliente(lista);
    final total = lista.fold<double>(0, (s, v) => s + v.valorRealizado);

    return Scaffold(
      body: Column(
        children: [
          HeaderCurvo(
            titulo: 'Vendas',
            subtitulo: '${lista.length} registro(s)',
            mostrarVoltar: false,
            rodape: Column(
              children: [
                TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou CPF...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _busca.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _busca.clear()),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chipPeriodo('Hoje', 0),
                    const SizedBox(width: 8),
                    _chipPeriodo('Este mês', 1),
                    const SizedBox(width: 8),
                    _chipPeriodo('Tudo', 2),
                    const Spacer(),
                    _botaoFiltroProduto(estado),
                  ],
                ),
              ],
            ),
          ),
          if (lista.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.summarize_outlined,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total no filtro: ',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    Fmt.moeda(total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: lista.isEmpty
                ? EstadoVazio(
                    icone: Icons.point_of_sale_outlined,
                    titulo: 'Nenhuma venda encontrada',
                    mensagem: _periodo == 0
                        ? 'Ainda não há vendas lançadas hoje.'
                        : 'Ajuste os filtros ou lance uma nova venda.',
                    acao: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TelaVendaForm(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const RotuloBotao('LANÇAR VENDA'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    itemCount: grupos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CartaoGrupoVenda(
                      grupo: grupos[i],
                      formato: (produto) => estado.formatoDoProduto(produto),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaVendaForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova venda',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  List<_GrupoVenda> _agruparPorCliente(List<Venda> vendas) {
    final mapa = <String, List<Venda>>{};
    for (final venda in vendas) {
      final chave = venda.cpf.isNotEmpty
          ? venda.cpf
          : '${venda.nome.trim().toLowerCase()}|${venda.telefone}';
      mapa.putIfAbsent(chave, () => []).add(venda);
    }
    final grupos = mapa.values.map(_GrupoVenda.new).toList();
    grupos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return grupos;
  }

  Widget _chipPeriodo(String texto, int valor) {
    final sel = _periodo == valor;
    return GestureDetector(
      onTap: () => setState(() => _periodo = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: sel ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _botaoFiltroProduto(AppState estado) {
    return GestureDetector(
      onTap: () async {
        final produtos = ['Todos', ...estado.produtos.map((p) => p.nome)];
        final escolha = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (_) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: produtos
                .map(
                  (p) => ListTile(
                    dense: true,
                    title: Text(
                      p,
                      style: TextStyle(
                        fontWeight: p == _filtroProduto
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: p == _filtroProduto
                        ? const Icon(
                            Icons.check,
                            color: AppColors.primary,
                            size: 19,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, p),
                  ),
                )
                .toList(),
          ),
        );
        if (escolha != null) setState(() => _filtroProduto = escolha);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _filtroProduto == 'Todos'
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 15, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Produto',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrupoVenda {
  final List<Venda> vendas;
  _GrupoVenda(this.vendas);
  String get nome => vendas.first.nome;
  String get cpf => vendas.first.cpf;
  String get telefone => vendas.first.telefone;
  double get total => vendas.fold(0, (s, v) => s + v.valorRealizado);
  List<String> get produtos => vendas.map((v) => v.produto).toSet().toList();
}

class _CartaoGrupoVenda extends StatelessWidget {
  final _GrupoVenda grupo;
  final String Function(String) formato;
  const _CartaoGrupoVenda({required this.grupo, required this.formato});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirDetalhes(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 4, height: 68, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(grupo.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${Fmt.cpf(grupo.cpf)} · ${grupo.vendas.length} lançamento(s)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...grupo.vendas.map((venda) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 5, color: AppColors.primary),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            venda.produto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          Fmt.valorPorFormato(venda.valorRealizado, formato(venda.produto)),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )),
                ]),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalhes(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), shrinkWrap: true, children: [
          ListTile(title: Text(grupo.nome, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${Fmt.cpf(grupo.cpf)}\n${Fmt.telefone(grupo.telefone)}\n${grupo.vendas.length} produto(s)/lançamento(s) no período')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
            title: const Text('Enviar mensagem pelo WhatsApp'),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await WhatsApp.abrir(telefone: grupo.telefone, mensagem: 'Olá, ${grupo.nome.split(' ').first}! Estou acompanhando suas compras.');
              if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefone inválido para abrir o WhatsApp.')));
            },
          ),
          const Divider(),
          ...grupo.vendas.map((venda) => ListTile(
            leading: const Icon(Icons.point_of_sale_outlined, color: AppColors.primary),
            title: Text(venda.produto, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${Fmt.data(venda.data)} · ${Fmt.valorPorFormato(venda.valorRealizado, formato(venda.produto))}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVendaForm(venda: venda)));
            },
          )),
        ],
      ),
      ),
    );
  }
}
