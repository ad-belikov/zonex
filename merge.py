import os

EXCLUDE_DIRS = {'.dart_tool', 'build', '.git', '.idea', 'android', 'ios', 'web', 'windows', 'linux', 'macos'}
INCLUDE_EXTENSIONS = {'.dart', '.yaml', '.json'}
# Исключаем файлы автогенерации кода Flutter
EXCLUDE_EXTENSIONS_ENDINGS = ('.g.dart', '.freezed.dart', '.generated.dart')

output_file = 'flutter_project_code.txt'

with open(output_file, 'w', encoding='utf-8') as outfile:
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        for file in files:
            # Пропускаем сам файл вывода, если он вдруг попал под критерии
            if file == output_file:
                continue
                
            _, ext = os.path.splitext(file)
            if ext in INCLUDE_EXTENSIONS:
                # Пропускаем сгенерированный код Flutter (.g.dart и т.д.)
                if file.endswith(EXCLUDE_EXTENSIONS_ENDINGS):
                    continue
                    
                file_path = os.path.join(root, file)
                
                # Подбираем правильный символ комментария для языка
                comment_sign = '#' if ext in {'.yaml', '.json'} else '//'
                
                # Записываем красивый и валидный разделитель
                outfile.write(f"\n\n{comment_sign} {'='*40}\n")
                outfile.write(f"{comment_sign} FILE: {file_path}\n")
                outfile.write(f"{comment_sign} {'='*40}\n\n")
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as infile:
                        outfile.write(infile.read())
                except Exception as e:
                    outfile.write(f"{comment_sign} [Ошибка чтения файла: {e}]\n")

print(f"Готово! Все файлы объединены в: {output_file}")
