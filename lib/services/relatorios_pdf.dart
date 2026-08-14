import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/formatters.dart';

/// Geração dos relatórios em PDF (equivalente ao módulo VBA modrelatorios).
class RelatoriosPdf {
  static const _azul = PdfColor.fromInt(0xFF0B4F9E);
  static const _laranja = PdfColor.fromInt(0xFFF58220);
  static const _cinza = PdfColor.fromInt(0xFF6B7785);
  static const _linha = PdfColor.fromInt(0xFFE3E8EF);
  static const _fundo = PdfColor.fromInt(0xFFF5F7FA);

  /// Monta um documento com cabeçalho institucional, tabela e totais.
  static Future<List<int>> gerar({
    required String titulo,
    required String periodo,
    required List<String> colunas,
    required List<List<String>> linhas,
    List<int>? alinharDireita,
    String? resumo,
    String usuario = '',
  }) async {
    final doc = pw.Document();
    final direita = alinharDireita ?? const <int>[];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 34),
        header: (ctx) => ctx.pageNumber == 1
            ? _cabecalho(titulo, periodo, usuario)
            : pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _cinza,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Gestor de Vendas · página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _cinza),
          ),
        ),
        build: (ctx) => [
          if (resumo != null) _caixaResumo(resumo),
          if (resumo != null) pw.SizedBox(height: 12),
          if (linhas.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: _fundo,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Nenhum registro encontrado para o período selecionado.',
                style: const pw.TextStyle(fontSize: 11, color: _cinza),
              ),
            )
          else
            _tabela(colunas, linhas, direita),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _cabecalho(String titulo, String periodo, String usuario) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const pw.BoxDecoration(color: _azul),
            width: double.infinity,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GESTOR DE VENDAS',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      titulo,
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  width: 34,
                  height: 34,
                  decoration: const pw.BoxDecoration(
                    color: _laranja,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const pw.BoxDecoration(color: _fundo),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  periodo,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: _cinza,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${usuario.isEmpty ? '' : '$usuario · '}Emitido em ${Fmt.data(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: _cinza),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _caixaResumo(String resumo) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: _fundo,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _linha),
      ),
      child: pw.Text(
        resumo,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: _azul,
        ),
      ),
    );
  }

  static pw.Widget _tabela(
    List<String> colunas,
    List<List<String>> linhas,
    List<int> direita,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: colunas,
      data: linhas,
      border: null,
      headerDecoration: const pw.BoxDecoration(color: _azul),
      headerStyle: pw.TextStyle(
        fontSize: 8.8,
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8.6),
      cellHeight: 20,
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: _fundo),
      cellAlignments: {
        for (var i = 0; i < colunas.length; i++)
          i: direita.contains(i)
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
      },
    );
  }
}
