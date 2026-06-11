require 'sqlite3'

db = SQLite3::Database.new('database/comisspro.db')

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT,
    email TEXT,
    senha TEXT,
    perfil TEXT
);
SQL

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS auditoria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario TEXT,
    acao TEXT,
    data DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS fechamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mes INTEGER,
    ano INTEGER,
    status TEXT
);
SQL

puts "Atualização concluída"