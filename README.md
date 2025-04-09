МИНИ БРАУЗЕР Rybakov

📥 Требования:
1) Python 3.10+
2) PyQt6 + tools

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Инструкция по запуску:

1. Установка Python
   
· Скачайте Python 3.10+ с официального сайта

· Запустите установщик

· Поставьте галочку "Add Python to PATH"

2. Установка зависимостей
   
· Откройте командную строку (Win+R → cmd) и выполните:
 «pip install PyQt6 PyQt6-WebEngine»

3. Подготовка файлов
   
· Скачайте архив с браузером

· Распакуйте в отдельную папку, чтобы там были:
 pb.py (основной файл); иконки (icon.png, back.png, forward.png, reload.png, home.png, bookmark.png, theme.png)

4. Запуск браузера
   
· Откройте командную строку

· Перейдите в папку с браузером:
 «cd C:\путь_к_папке»
 
· Запустите:
 «python pb.py»

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

🖥 Интерфейс:

Панель инструментов:
1) Кнопки навигации
2) Выбор поисковой системы
3) Добавление в закладки
4) Переключение темы

Меню:
1) История посещений
2) Управление закладками

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

🛠 Функционал
1) Вкладки (открытие/закрытие)
2) Навигация: назад, вперед, обновить, домой
3) История посещений (автосохранение в БД)
4) Закладки (добавление/удаление)
5) Темная/светлая тема (меняет цвет страницы и интерфейса)
6) Выбор поисковика: Google, Bing, DuckDuckGo
