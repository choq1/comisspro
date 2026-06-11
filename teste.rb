require 'sqlite3'

db = SQLite3::Database.new('database/comisspro.db')

puts db.execute("
SELECT name
FROM sqlite_master
WHERE type='table'
").inspect