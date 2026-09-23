import os

# Исключаем системные папки Flutter и бинарники, чтобы файл не раздулся до гигабайтов
EXCLUDE_DIRS = {'.dart_tool', 'build', '.git', '.idea', 'android', 'ios', 'web', 'windows', 'linux', 'macos'}
# Включаем только важные для анализа типы файлов
INCLUDE_EXTENSIONS = {'.dart', '.yaml', '.json'}

output_file = 'flutter_project_code.txt'

with open(output_file, 'w', encoding='utf-8') as outfile:
    for root, dirs, files in os.walk('.'):
        # Фильтруем папки на лету
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        for file in files:
            _, ext = os.path.splitext(file)
            if ext in INCLUDE_EXTENSIONS:
                file_path = os.path.join(root, file)
                
                # Записываем красивый разделитель для анализатора
                outfile.write(f"\n\n{'='*40}\n")
                outfile.write(f"FILE: {file_path}\n")
                outfile.write(f"{'='*40}\n\n")
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as infile:
                        outfile.write(infile.read())
                except Exception as e:
                    outfile.write(f"[Ошибка чтения файла: {e}]\n")

print(f"Готово! Все файлы объединены в: {output_file}")
