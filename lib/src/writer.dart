import 'package:mustache4dart/mustache4dart.dart';
import 'collector.dart';
import 'page_config_map_util.dart';
import 'tpl.dart';
import 'package:analyzer/dart/element/element.dart';

class Writer {
  Collector collector;
  Writer(this.collector);

  String instanceCreated() {
    return instanceCreatedTpl;
  }

  String instanceFromClazz() {
    final StringBuffer buffer = new StringBuffer();
    buffer..writeln('switch(clazz) {');
    final Map<String, bool> mappedClazz = <String, bool>{};
    final Function writeClazzCase = (Map<String, dynamic> config) {
      final dynamic clazz = config[wK('clazz')];
      if (clazz is ClassElement) {
          if (mappedClazz[clazz.name] == null) {
            mappedClazz[clazz.name] = true;
          } else {
            return;
          }

          if (clazz.constructors.isEmpty || clazz.constructors.first.type.parameters.isEmpty) {
            buffer.writeln('case ${clazz.name}: return new ${clazz.name}();');
          } else {
            buffer.writeln('case ${clazz.name}: return new ${clazz.name}(option);');
          }
      }
      // buffer.writeln('case ${clazz}: return new ${clazz}(option);');
    };
    collector.routerMap
        .forEach((String url, List<Map<String, dynamic>> configList) {
      configList.forEach(writeClazzCase);
    });
    buffer..writeln('default:return null;')..writeln('}');
    return buffer.toString();
  }

  String write() {
    final List<Map<String, String>> refs = <Map<String, String>>[];
    final Function addRef = (String path) {
      refs.add(<String, String>{'path': path});
    };
    collector.importList.forEach(addRef);
    return render(clazzTpl, <String, dynamic>{
      'refs': refs,
      'instanceCreated': instanceCreated(),
      'instanceFromClazz': instanceFromClazz(),
      'routerMap': collector.routerMap.map((String key, dynamic element) {
        if(element is List) {
          List<Map> list = element.map<Map>((dynamic mapInList) {
            if (mapInList is Map) {
              return mapInList.map((lkey, lvalue) {
                if (lvalue is ClassElement) {
                  print('---- ${lvalue.name}');
                  return MapEntry(lkey, lvalue.name);
                }
                return MapEntry(lkey, lvalue);
              });
            }
            return mapInList;
          }).toList();
          return MapEntry(key, list);
        }
        return MapEntry(key, element);
      }).toString()
    });
  }
}
