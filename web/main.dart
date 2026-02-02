import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:knx_parser/knx_parser.dart';

Element buildJsonTree(dynamic data, {String? key, int depth = 0}) {
  final wrap = DivElement()..className = 'json-node';

  if (data is Map) {
    final head = DivElement()..className = 'json-line json-expandable';
    final toggle = SpanElement()
      ..className = 'json-toggle'
      ..text = '▼'
      ..attributes['aria-label'] = 'Thu gọn';
    String keyLabel = key ?? '';
    if (key != null) {
      head.append(SpanElement()
        ..className = 'json-key'
        ..text = '"$keyLabel"');
      head.append(SpanElement()
        ..className = 'json-colon'
        ..text = ': ');
    }
    head.append(SpanElement()
      ..className = 'json-brace'
      ..text = '{');
    final countText = ' ${data.length} ${data.length == 1 ? 'key' : 'keys'} ';
    final count = SpanElement()
      ..className = 'json-count'
      ..text = countText;
    head.append(count);
    head.append(SpanElement()
      ..className = 'json-brace'
      ..text = '}');
    head.insertBefore(toggle, head.firstChild);
    wrap.append(head);

    final children = DivElement()..className = 'json-children';
    for (final e in data.entries) {
      children.append(
          buildJsonTree(e.value, key: e.key as String, depth: depth + 1));
    }
    wrap.append(children);

    head.onClick.listen((_) {
      wrap.classes.toggle('collapsed');
      toggle.text = wrap.classes.contains('collapsed') ? '▶' : '▼';
      toggle.attributes['aria-label'] =
          wrap.classes.contains('collapsed') ? 'Mở rộng' : 'Thu gọn';
    });
    return wrap;
  }

  if (data is List) {
    final head = DivElement()..className = 'json-line json-expandable';
    final toggle = SpanElement()
      ..className = 'json-toggle'
      ..text = '▼'
      ..attributes['aria-label'] = 'Thu gọn';
    if (key != null) {
      head.append(SpanElement()
        ..className = 'json-key'
        ..text = '"$key"');
      head.append(SpanElement()
        ..className = 'json-colon'
        ..text = ': ');
    }
    head.append(SpanElement()
      ..className = 'json-bracket'
      ..text = '[');
    final countText = ' ${data.length} ${data.length == 1 ? 'item' : 'items'} ';
    final count = SpanElement()
      ..className = 'json-count'
      ..text = countText;
    head.append(count);
    head.append(SpanElement()
      ..className = 'json-bracket'
      ..text = ']');
    head.insertBefore(toggle, head.firstChild);
    wrap.append(head);

    final children = DivElement()..className = 'json-children';
    for (var i = 0; i < data.length; i++) {
      children.append(buildJsonTree(data[i], key: '$i', depth: depth + 1));
    }
    wrap.append(children);

    head.onClick.listen((_) {
      wrap.classes.toggle('collapsed');
      toggle.text = wrap.classes.contains('collapsed') ? '▶' : '▼';
      toggle.attributes['aria-label'] =
          wrap.classes.contains('collapsed') ? 'Mở rộng' : 'Thu gọn';
    });
    return wrap;
  }

  // primitive
  final line = DivElement()..className = 'json-line json-leaf';
  if (key != null) {
    line.append(SpanElement()
      ..className = 'json-key'
      ..text = '"$key"');
    line.append(SpanElement()
      ..className = 'json-colon'
      ..text = ': ');
  }
  if (data is String) {
    final escaped = data
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    line.append(SpanElement()
      ..className = 'json-string'
      ..text = '"$escaped"');
  } else if (data is num) {
    line.append(SpanElement()
      ..className = 'json-number'
      ..text = '$data');
  } else if (data is bool) {
    line.append(SpanElement()
      ..className = 'json-bool'
      ..text = '$data');
  } else if (data == null) {
    line.append(SpanElement()
      ..className = 'json-null'
      ..text = 'null');
  }
  wrap.append(line);
  return wrap;
}

void main() {
  final fileInput =
      document.getElementById('fileInput')! as FileUploadInputElement;
  final passwordInput =
      document.getElementById('passwordInput')! as InputElement;
  final parseBtn = document.getElementById('parseBtn')! as ButtonElement;
  final resultSection = document.getElementById('resultSection')!;
  final errorSection = document.getElementById('errorSection')!;
  final jsonTreeView = document.getElementById('jsonTreeView')!;
  final jsonOutput = document.getElementById('jsonOutput')! as PreElement;
  final errorMessage = document.getElementById('errorMessage')! as PreElement;
  final status = document.getElementById('status')!;
  final downloadBtn = document.getElementById('downloadBtn')! as ButtonElement;
  final viewTabs = document.querySelectorAll('.view-tab');

  String? lastJsonString;
  String? lastFileName;

  final fileNameEl = document.getElementById('fileName')!;

  fileInput.onChange.listen((_) {
    if (fileInput.files != null && fileInput.files!.isNotEmpty) {
      final name = fileInput.files!.first.name;
      fileNameEl.text = name;
      fileNameEl.className = 'file-name';
      parseBtn.disabled = false;
      lastFileName = name;
    } else {
      fileNameEl.text = '';
    }
  });

  parseBtn.onClick.listen((_) async {
    if (fileInput.files == null || fileInput.files!.isEmpty) return;

    resultSection.hidden = true;
    errorSection.hidden = true;
    parseBtn.disabled = true;
    parseBtn.text = 'Đang xử lý...';

    final file = fileInput.files!.first;
    final password = passwordInput.value?.trim().isEmpty ?? true
        ? null
        : passwordInput.value!.trim();

    final reader = FileReader();
    reader.onLoad.listen((_) {
      try {
        final result = reader.result;
        final List<int> bytes;
        if (result is Uint8List) {
          bytes = result.toList();
        } else if (result is ByteBuffer) {
          bytes = Uint8List.view(result).toList();
        } else {
          throw StateError(
              'Không đọc được dữ liệu file (type: ${result.runtimeType})');
        }
        final parser = KnxProjectParser();
        final project = parser.parseBytes(bytes, password: password);
        final jsonMap = project.toJson();
        final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
        lastJsonString = jsonStr;
        lastFileName ??= file.name.replaceAll(RegExp(r'\.knxproj$'), '.json');
        if (!lastFileName!.endsWith('.json'))
          lastFileName = '$lastFileName.json';

        status.text = 'Project: ${project.projectInfo.name} — '
            '${project.installations.length} installation(s), '
            '${project.datapointTypes.length} datapoint type(s).';
        jsonOutput.text = jsonStr;
        jsonTreeView.children.clear();
        jsonTreeView.append(buildJsonTree(jsonMap));
        resultSection.hidden = false;
      } catch (e, st) {
        errorMessage.text = '$e\n\n$st';
        errorSection.hidden = false;
      } finally {
        parseBtn.disabled = false;
        parseBtn.text = 'Parse sang JSON';
      }
    });
    reader.onError.listen((_) {
      errorMessage.text = 'Không đọc được file.';
      errorSection.hidden = false;
      parseBtn.disabled = false;
      parseBtn.text = 'Parse sang JSON';
    });
    reader.readAsArrayBuffer(file);
  });

  for (final tab in viewTabs) {
    (tab as ButtonElement).onClick.listen((_) {
      final view = tab.attributes['data-view']!;
      for (final t in viewTabs) {
        (t as ButtonElement).attributes['aria-pressed'] =
            t == tab ? 'true' : 'false';
        if (t == tab) {
          t.classes.add('active');
        } else {
          t.classes.remove('active');
        }
      }
      final showTree = view == 'tree';
      jsonTreeView.hidden = !showTree;
      jsonOutput.hidden = showTree;
    });
  }

  downloadBtn.onClick.listen((_) {
    if (lastJsonString == null || lastFileName == null) return;
    final blob = Blob([lastJsonString!], 'application/json');
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement()
      ..href = url
      ..download = lastFileName!
      ..click();
    Url.revokeObjectUrl(url);
  });
}
