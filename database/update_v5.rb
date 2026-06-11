require 'sqlite3'

db = SQLite3::Database.new('database/comisspro.db')

begin

  db.execute "
    ALTER TABLE vendas
    ADD COLUMN produto TEXT
  "

rescue
end

begin

  db.execute "
    ALTER TABLE vendas
    ADD COLUMN custo REAL DEFAULT 0
  "

rescue
end

begin

  db.execute "
    ALTER TABLE vendas
    ADD COLUMN ativo INTEGER DEFAULT 1
  "

rescue
end

puts "Banco atualizado com sucesso!"