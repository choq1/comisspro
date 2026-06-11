require 'fileutils'
require 'sqlite3'

FileUtils.mkdir_p('database')

db = SQLite3::Database.new('database/comisspro.db')

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS vendedores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    percentual REAL DEFAULT 10
);
SQL

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS vendas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vendedor_id INTEGER,
    valor REAL,
    comissao REAL,
    data DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(vendedor_id) REFERENCES vendedores(id)
);
SQL

puts "Banco criado com sucesso!"