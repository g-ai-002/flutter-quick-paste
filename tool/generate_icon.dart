/// 生成 assets/tray_icon.ico（绿色圆形，32×32，BMP 编码）
///
/// 用法: dart run tool/generate_icon.dart
library;

import 'dart:io';
import 'dart:math';

void main() {
  final icoBytes = _generateIco();
  final dir = Directory('assets');
  if (!dir.existsSync()) dir.createSync();
  final file = File('assets/tray_icon.ico');
  file.writeAsBytesSync(icoBytes);
  print('Created ${file.path} (${icoBytes.length} bytes)');
}

List<int> _generateIco() {
  const size = 32;
  const cx = 15.5;
  const cy = 15.5;
  const outerR = 15.0;
  const innerR = 13.5;

  // --- BGRA 像素数据 (top-down, Windows ICO 需要 bottom-up) ---
  final topDown = List<int>.filled(size * size * 4, 0);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final d = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      final i = (y * size + x) * 4;
      if (d > outerR) {
        topDown[i] = 0;      // B
        topDown[i + 1] = 0;  // G
        topDown[i + 2] = 0;  // R
        topDown[i + 3] = 0;  // A
      } else if (d >= innerR) {
        topDown[i] = 255;    // B
        topDown[i + 1] = 255;// G
        topDown[i + 2] = 255;// R
        topDown[i + 3] = 255;// A
      } else {
        topDown[i] = 0;      // B
        topDown[i + 1] = 175;// G
        topDown[i + 2] = 76; // R
        topDown[i + 3] = 255;// A
      }
    }
  }

  // 反转 Y 轴 → bottom-up（BMP / ICO 格式要求）
  final bottomUp = List<int>.filled(size * size * 4, 0);
  for (int y = 0; y < size; y++) {
    final srcOff = y * size * 4;
    final dstOff = (size - 1 - y) * size * 4;
    for (int x = 0; x < size * 4; x++) {
      bottomUp[dstOff + x] = topDown[srcOff + x];
    }
  }

  // --- BITMAPINFOHEADER (40 bytes) ---
  final bmiHeader = <int>[
    40, 0, 0, 0, // biSize
    size, 0, 0, 0, // biWidth
    size * 2, 0, 0, 0, // biHeight (XOR + AND mask 合并高度)
    1, 0, // biPlanes
    32, 0, // biBitCount
    0, 0, 0, 0, // biCompression = BI_RGB
    0, 0, 0, 0, // biSizeImage (0 for uncompressed)
    0, 0, 0, 0, // biXPelsPerMeter
    0, 0, 0, 0, // biYPelsPerMeter
    0, 0, 0, 0, // biClrUsed
    0, 0, 0, 0, // biClrImportant
  ];

  // --- AND mask：32bpp 有 Alpha 通道，AND mask 全 0 ---
  final andMask = List<int>.filled((size * size) ~/ 8, 0);

  // --- 组装 image data ---
  final imageData = <int>[
    ...bmiHeader,
    ...bottomUp,
    ...andMask,
  ];

  final imageSize = imageData.length;
  const imageOffset = 22; // 6 + 16

  // --- ICO 头部 (6 bytes) ---
  final ico = <int>[
    0, 0, // 保留
    1, 0, // 类型: ICO
    1, 0, // 图像数量: 1
  ];

  // --- 目录项 (16 bytes) ---
  ico.addAll([
    size, // 宽度
    size, // 高度
    0, // 颜色数
    0, // 保留
    1, 0, // 颜色平面
    32, 0, // 每像素位数
    // 图像数据大小 (LE)
    imageSize & 0xFF,
    (imageSize >> 8) & 0xFF,
    (imageSize >> 16) & 0xFF,
    (imageSize >> 24) & 0xFF,
    // 图像数据偏移 (LE)
    imageOffset & 0xFF,
    (imageOffset >> 8) & 0xFF,
    (imageOffset >> 16) & 0xFF,
    (imageOffset >> 24) & 0xFF,
  ]);

  ico.addAll(imageData);
  return ico;
}