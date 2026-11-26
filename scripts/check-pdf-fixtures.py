"""Verifica e renderiza as amostras sintéticas geradas por pdf_privacidade_test.dart."""

import argparse
from contextlib import closing
from pathlib import Path
import re

import pypdfium2 as pdfium


def verificar(caminho, textos, repeticoes=None):
    with pdfium.PdfDocument(caminho) as pdf:
        paginas = []
        for pagina in pdf:
            with closing(pagina), closing(pagina.get_textpage()) as texto_pagina:
                paginas.append(texto_pagina.get_text_bounded())
        total = len(paginas)
        conteudos = []
        for numero, pagina in enumerate(paginas, 1):
            rodape = rf"(?m)^\s*{numero}\s*/\s*{total}\s*$"
            conteudo, encontrados = re.subn(rodape, "", pagina)
            assert encontrados == 1, f"{caminho.name}: rodapé incorreto na página {numero}"
            conteudos.append(conteudo)
        texto = " ".join(" ".join(conteudos).split())
        for detalhe in textos:
            assert detalhe in texto, f"{caminho.name}: texto ausente: {detalhe}"
        for marcador in ("INTERNOCLIENTE927", "INTERNOITEM639", "INTERNOORCAMENTO417"):
            assert marcador not in texto, f"{caminho.name}: nota interna no PDF"
        assert "\ufffd" not in texto, f"{caminho.name}: caractere corrompido"
        if repeticoes is not None:
            assert len(paginas) > 1
            assert texto.count(repeticoes[0]) == repeticoes[1]
        ultima = len(paginas)
        for numero in {1, min(2, ultima), min(3, ultima), ultima}:
            with closing(pdf[numero - 1]) as pagina, closing(pagina.render(scale=1.4)) as bitmap:
                bitmap.to_pil().save(
                    caminho.with_name(f"{caminho.stem}-p{numero}.png")
                )
        print(f"{caminho.name}: texto extraído e {ultima} página(s) verificada(s)")
        return texto


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("amostras", type=Path)
    args = parser.parse_args()
    verificar(
        args.amostras / "historico-privado.pdf",
        ("João Gonçalves — Açucena", "Peça histórica", "0,125 m", "R$ 0,12"),
    )
    verificar(
        args.amostras / "orcamento-longo.pdf",
        (
            "João Gonçalves — Açucena",
            "Especificação aprovada — aço galvanizado, ½ polegada e €",
            "FIMDETALHE",
            "Peça 90",
            "0,125 m²",
            "R$ 11,70",
            "R$ 0,20",
            "R$ 11,50",
            "Prazo de instalação confirmado com o cliente.",
        ),
        ("Descrição comprida — corte, fixação e acabamento.", 245),
    )
    endereco = verificar(
        args.amostras / "endereco-longo.pdf",
        ("Linha de endereço 1", "Linha de endereço 150", "R$ 8,25"),
    )
    linhas = re.findall(r"Linha\s*de\s*endereço\s*(\d+)", endereco)
    assert list(map(int, linhas)) == list(range(1, 151)), "Endereço incompleto ou fora de ordem"


if __name__ == "__main__":
    main()
