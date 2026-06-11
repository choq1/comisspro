require 'sqlite3'

db = SQLite3::Database.new('database/comisspro.db')

%w[
usuarios
vendedores
vendas
metas
auditoria
fechamento
].each do |tabela|

  puts "\n=== #{tabela.upcase} ==="

  puts db.execute("
    PRAGMA table_info(#{tabela})
  ").map { |c| c[1] }

end