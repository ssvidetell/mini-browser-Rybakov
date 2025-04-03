"""Мини браузер Rybakov"""


import sys
import sqlite3
from datetime import datetime
from PyQt6.QtWidgets import (QApplication, QMainWindow, QVBoxLayout, QWidget, QLineEdit, 
                            QToolBar, QTabWidget, QComboBox, QMenu, QMessageBox, QLabel, QDialog, QTableWidget, QTableWidgetItem, QListWidget, QListWidgetItem, QHBoxLayout, QPushButton)
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtCore import QUrl, Qt
from PyQt6.QtGui import QIcon, QAction

class MiniBrowser(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Rybakov")
        self.resize(1200, 800)
        self.setWindowIcon(QIcon("icon.png"))
        
        # ИНИЦИАЛИЗАЦИЯ БД
        self.init_db()
        
        # НАСТРОКИ ПО УМОЛЧАНИЮ
        self.current_theme = "light"
        self.search_engines = {
            "Google": "https://www.google.com/search?q={}",
            "Bing": "https://www.bing.com/search?q={}",
            "DuckDuckGo": "https://duckduckgo.com/?q={}"
        }
        self.current_search_engine = "Google"
        
        # СОЗДАНИЕ ИНТЕРФЕЙСА
        self.create_ui()
        
        # ПЕРВАЯ ВКЛАДКА
        self.add_tab(QUrl("https://www.google.com"))
    
    def init_db(self):
        """инициализация бд для истории и закладок"""
        self.history_db = sqlite3.connect("history.db")
        self.history_cursor = self.history_db.cursor()
        self.history_cursor.execute("""
            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT,
                title TEXT,
                visit_time DATETIME
            )
        """)
        
        self.bookmarks_db = sqlite3.connect("bookmarks.db")
        self.bookmarks_cursor = self.bookmarks_db.cursor()
        self.bookmarks_cursor.execute("""
            CREATE TABLE IF NOT EXISTS bookmarks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT,
                title TEXT
            )
        """)
    
    def create_ui(self):
        """создание основного интерфейса"""
        # ИНСТРУМЕНТЫ
        self.toolbar = QToolBar()
        self.addToolBar(self.toolbar)
        
        # НАВИГАЦИЯ
        back_btn = QAction(QIcon("back.png"), "Назад", self)
        back_btn.triggered.connect(self.back)
        self.toolbar.addAction(back_btn)
        
        reload_btn = QAction(QIcon("reload.png"), "Обновить", self)
        reload_btn.triggered.connect(self.reload)
        self.toolbar.addAction(reload_btn)

        forward_btn = QAction(QIcon("forward.png"), "Вперёд", self)
        forward_btn.triggered.connect(self.forward)
        self.toolbar.addAction(forward_btn)
        
        home_btn = QAction(QIcon("home.png"), "Домой", self)
        home_btn.triggered.connect(self.home)
        self.toolbar.addAction(home_btn)
        
        # АДРЕСНАЯ СТРОКА
        self.url_bar = QLineEdit()
        self.url_bar.returnPressed.connect(self.navigate_to_url)
        self.toolbar.addWidget(self.url_bar)
        
        # ВЫБОР ПОИСКОВИКА
        self.search_engine_box = QComboBox()
        self.search_engine_box.addItems(self.search_engines.keys())
        self.search_engine_box.currentTextChanged.connect(self.change_search_engine)
        self.toolbar.addWidget(self.search_engine_box)
        
        # КНОПКА ЗАКЛАДОК
        bookmark_btn = QAction(QIcon("bookmark.png"), "Добавить в закладки", self)
        bookmark_btn.triggered.connect(self.add_bookmark)
        self.toolbar.addAction(bookmark_btn)
        
        # КНОПКА ТЕМЫ
        self.theme_btn = QAction(QIcon("theme.png"), "Сменить тему", self)
        self.theme_btn.triggered.connect(self.toggle_theme)
        self.toolbar.addAction(self.theme_btn)
        
        # ВКЛАДКИ
        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.setCentralWidget(self.tabs)
        
        # МЕНЮ
        self.create_menu()
    
    def create_menu(self):
        """создание меню браузера"""
        menubar = self.menuBar()
        
        # Меню "ФАЙЛ"
        file_menu = menubar.addMenu("Файл")
        new_tab_action = QAction("Новая вкладка", self)
        new_tab_action.triggered.connect(lambda: self.add_tab(QUrl("https://www.google.com"), "Новая вкладка"))
        file_menu.addAction(new_tab_action)
        
        # Меню "ИСТОРИЯ"
        history_menu = menubar.addMenu("История")
        show_history_action = QAction("Показать историю", self)
        show_history_action.triggered.connect(self.show_history)
        history_menu.addAction(show_history_action)
        
        # Меню "ЗАКЛАДКИ"
        bookmarks_menu = menubar.addMenu("Закладки")
        show_bookmarks_action = QAction("Показать закладки", self)
        show_bookmarks_action.triggered.connect(self.show_bookmarks)
        bookmarks_menu.addAction(show_bookmarks_action)
    
    def add_tab(self, url, title="Новая вкладка"):
        """добавление новой вкладки"""
        browser_tab = QWebEngineView()
        browser_tab.setUrl(url)
        idx = self.tabs.addTab(browser_tab, title)
        self.tabs.setCurrentIndex(idx)
        
        # ОБНОВЛЕНИЕ URL ПРИ ИЗМЕНЕНИИ
        browser_tab.urlChanged.connect(lambda q: self.update_url(q, browser_tab))
        browser_tab.titleChanged.connect(lambda t: self.update_title(t, browser_tab))
    
    def update_url(self, url, tab):
        """обновление адресной строки"""
        if tab == self.tabs.currentWidget():
            self.url_bar.setText(url.toString())
            
            # ДОБАВЛЕНИЕ В ИСТОРИЮ
            title = self.tabs.tabText(self.tabs.currentIndex())
            self.history_cursor.execute(
                "INSERT INTO history (url, title, visit_time) VALUES (?, ?, ?)",
                (url.toString(), title, datetime.now())
            )
            self.history_db.commit()
    
    def update_title(self, title, tab):
        """обновление заголовка вкладки"""
        idx = self.tabs.indexOf(tab)
        self.tabs.setTabText(idx, title[:20] + "...")
    
    def navigate_to_url(self):
        """переход по url или поиск"""
        url = self.url_bar.text()
        if "." not in url:
            url = self.search_engines[self.current_search_engine].format(url)
        self.tabs.currentWidget().setUrl(QUrl(url))
    
    def change_search_engine(self, engine):
        """смена поисковой системы"""
        self.current_search_engine = engine
    
    def back(self):
        """назад'"""
        self.tabs.currentWidget().back()
    
    def forward(self):
        """вперёд'"""
        self.tabs.currentWidget().forward()
    
    def reload(self):
        """обновить'"""
        self.tabs.currentWidget().reload()
    
    def home(self):
        """домой'"""
        self.tabs.currentWidget().setUrl(QUrl("https://www.google.com"))
    
    def close_tab(self, index):
        """закрыть вкладку"""
        if self.tabs.count() > 1:
            self.tabs.removeTab(index)
    
    def add_bookmark(self):
        """добавление страницы в закладки"""
        current_tab = self.tabs.currentWidget()
        url = current_tab.url().toString()
        title = self.tabs.tabText(self.tabs.currentIndex())
        
        self.bookmarks_cursor.execute(
            "INSERT INTO bookmarks (url, title) VALUES (?, ?)",
            (url, title)
        )
        self.bookmarks_db.commit()
        QMessageBox.information(self, "Закладка добавлена", f"Страница '{title}' добавлена в закладки!")
    
    def show_history(self):
        """показать историю"""
        history_dialog = QDialog(self)
        history_dialog.setWindowTitle("История посещений")
        history_dialog.resize(600, 400)
        
        layout = QVBoxLayout()
        
        # ТАБЛИЦА ДЛЯ ОТОБРАЖЕНИЯ ИСТОРИИ
        table = QTableWidget()
        table.setColumnCount(3)
        table.setHorizontalHeaderLabels(["Дата", "Название", "URL"])
        table.verticalHeader().setVisible(False)
        table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        
        # ПОЛУЧЕНИЕ ИСТОРИИ ИЗ БД
        self.history_cursor.execute("SELECT url, title, visit_time FROM history ORDER BY visit_time DESC")
        history = self.history_cursor.fetchall()
        
        table.setRowCount(len(history))
        for row, (url, title, time) in enumerate(history):
            table.setItem(row, 0, QTableWidgetItem(str(time)))
            table.setItem(row, 1, QTableWidgetItem(title))
            table.setItem(row, 2, QTableWidgetItem(url))
        
        table.resizeColumnsToContents()
        
        # КНОПКА ЗАКРЫТИЯ
        close_btn = QPushButton("Закрыть")
        close_btn.clicked.connect(history_dialog.close)
        
        layout.addWidget(table)
        layout.addWidget(close_btn)
        history_dialog.setLayout(layout)
        history_dialog.exec()

    def show_bookmarks(self):
        """показать закладоки в диалоговом окне"""
        bookmarks_dialog = QDialog(self)
        bookmarks_dialog.setWindowTitle("Закладки")
        bookmarks_dialog.resize(500, 300)
        
        layout = QVBoxLayout()
        
        # СПИСОК ЗАКЛАДОК
        list_widget = QListWidget()
        
        # ПОЛУЧЕНИЕ ЗАКЛАДКИ ИЗ БД
        self.bookmarks_cursor.execute("SELECT url, title FROM bookmarks")
        bookmarks = self.bookmarks_cursor.fetchall()
        
        for url, title in bookmarks:
            item = QListWidgetItem(title)
            item.setData(Qt.ItemDataRole.UserRole, url)
            list_widget.addItem(item)
        
        # ОБРАБОТЧИК КЛИКА ПО ЗАКЛАДКЕ
        def open_bookmark(item):
            url = item.data(Qt.ItemDataRole.UserRole)
            self.tabs.currentWidget().setUrl(QUrl(url))
            bookmarks_dialog.close()
        
        list_widget.itemClicked.connect(open_bookmark)
        
        # КНОПКИ УПРАВЛЕНИЯ
        btn_layout = QHBoxLayout()
        
        delete_btn = QPushButton("Удалить")
        def delete_bookmark():
            selected = list_widget.currentItem()
            if selected:
                url = selected.data(Qt.ItemDataRole.UserRole)
                self.bookmarks_cursor.execute("DELETE FROM bookmarks WHERE url = ?", (url,))
                self.bookmarks_db.commit()
                list_widget.takeItem(list_widget.row(selected))
        
        delete_btn.clicked.connect(delete_bookmark)
        
        close_btn = QPushButton("Закрыть")
        close_btn.clicked.connect(bookmarks_dialog.close)
        
        btn_layout.addWidget(delete_btn)
        btn_layout.addWidget(close_btn)
        
        layout.addWidget(list_widget)
        layout.addLayout(btn_layout)
        bookmarks_dialog.setLayout(layout)
        bookmarks_dialog.exec()
    
    def toggle_theme(self):
        """переключение темы страницы"""
        if self.current_theme == "light":
            # ВКЛ ТЕМНУЮ ТЕМУ
            js_dark_theme = """
            document.body.style.backgroundColor = '#1e1e1e';
            document.body.style.color = '#ffffff';
            """
            self.tabs.currentWidget().page().runJavaScript(js_dark_theme)
            
            # ТЕМНЫЙ СТИЛЬ ИНТЕРФЕЙСА
            self.setStyleSheet("""
                QToolBar { background-color: #2d2d2d; }
                QLineEdit { background-color: #3d3d3d; color: white; }
                QTabBar::tab { background: #2d2d2d; color: white; }
                QTabBar::tab:selected { background: #1e1e1e; }
            """)
            self.current_theme = "dark"
        else:
            # ВЕРНУТЬ СВЕТЛУЮ ТЕМУ
            js_light_theme = """
            document.body.style.backgroundColor = '';
            document.body.style.color = '';
            """
            self.tabs.currentWidget().page().runJavaScript(js_light_theme)
            
            # СВЕТЛЫЙ СТИЛЬ ИНТЕРФЕЙСА
            self.setStyleSheet("")
            self.current_theme = "light"

if __name__ == "__main__":
    app = QApplication(sys.argv)
    browser = MiniBrowser()
    browser.show()
    sys.exit(app.exec())
