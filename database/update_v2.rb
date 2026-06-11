require 'sqlite3'

db = SQLite3::Database.new('database/comisspro.db')

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS metas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    valor REAL NOT NULL,
    mes INTEGER NOT NULL,
    ano INTEGER NOT NULL
);
SQL

puts "Tabela metas criada com sucesso!"