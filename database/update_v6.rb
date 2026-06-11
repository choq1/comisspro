require 'sqlite3'

db = SQLite3::Database.new('database/comisspro.db')

begin

  db.execute "
    ALTER TABLE usuarios
    ADD COLUMN ativo INTEGER DEFAULT 1
  "

rescue
end

puts "Usuarios atualizados!"