import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main(List<String> pars) async {
  String fileName = '';
  int cols = 80;
  String asciiGradient = ' .:+*X#';
  if (pars.length == 0) {
    print(help);
    exit(1);
  } else if (pars.length == 1) {
    fileName = pars[0];
  } else {
    fileName = pars[0];

    //asciiGradient
    asciiGradient =
        pars.firstWhere((e) => e.startsWith('-g'), orElse: () => asciiGradient);
    if (asciiGradient.startsWith('-g'))
      asciiGradient = asciiGradient.substring(2);

    //cols
    String strCols =
        pars.firstWhere((e) => e.startsWith('-c'), orElse: () => '80');
    if (strCols.startsWith('-c')) cols = int.parse(strCols.substring(2));
  }

  Uint8List bytes = await File(fileName).readAsBytes();
  img.Image imagem = img.decodeImage(bytes);
  AsciiArt asciiArt = AsciiArt(imagem, cols, asciiGradient);
  print(asciiArt.render());
}

const String help = ''' 
AsciiArt

Usage: asciiart FILE.JPG -cCOLUMNS -gASCIIGRADIENT

Ex:
asciiart file.jpg
  To output the image rendered in 80 columns

asciiart file.jpg -c40
  To output the image rendered in 40 columns

asciiart file.jpg -g".:"
  To output the image rendered with ".:" characters
''';

class AsciiArt {
  img.Image _imagem;
  int charsLargura;
  String asciiGradient;

  AsciiArt(this._imagem, this.charsLargura, this.asciiGradient);

  double get blocksWidth => _imagem.width / charsLargura;
  double get blocksHeight => blocksWidth * 2;
  double get charsAltura => _imagem.height / blocksHeight;

  String render() {
    String resposta = '';
    for (int l = 0; l <= charsAltura - 1; l++) {
      for (int c = 0; c <= charsLargura - 1; c++) {
        resposta += _charDoBloco(_corMedia(l, c));
      }
      resposta += "\n";
    }
    return resposta;
  }

  String _charDoBloco(int cor) {
    int faixaValores = (255 / asciiGradient.length).floor();
    return asciiGradient[cor ~/ faixaValores];
  }

  int _corMedia(int blocoL, int blocoC) {
    img.Image blocoAtual = _bloco(blocoL, blocoC);
    int r = 0, g = 0, b = 0;
    int media = 0;
    int acumulado = 0;
    int cor;
    for (int y = 0; y <= blocoAtual.height - 1; y++) {
      for (int x = 0; x <= blocoAtual.width - 1; x++) {
        //      AA        BB        GG        RR
        //   10101010  10101010  10101010  10101010
        //   00000000  11111111  00000000  00000000
        // & 00000000  10101010  00000000  00000000

        cor = blocoAtual.getPixel(y, x);
        r = cor & 0x000000FF;
        g = (cor & 0x0000FF00) ~/ 0x100;  // ~/0x100 ou >> 8
        b = (cor & 0x00FF0000) ~/ 0x10000;  // ~/0x10000 ou >> 16
        media = (r + g + b) ~/ 3;
        acumulado += media;
      }
    }
    int mediaFinal = acumulado ~/ (blocoAtual.width * blocoAtual.height);
    return mediaFinal;
  }

  img.Image _bloco(int l, int c) {
    img.Image resposta = img.Image(blocksWidth.floor(), blocksHeight.floor());
    for (int y = 0; y <= blocksHeight - 1; y++) {
      for (int x = 0; x <= blocksWidth - 1; x++) {
        resposta.setPixel(
          y,
          x,
          _imagem.getPixel(
            (c * blocksWidth + x).floor(),
            (l * blocksHeight + y).floor(),
          ),
        );
      }
    }
    return resposta;
  }
}
