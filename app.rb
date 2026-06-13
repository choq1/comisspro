require 'sinatra'
require 'sqlite3'
require 'sequel'

#require_relative 'services/excel_exporter'
#require_relative 'services/pdf_exporter'

enable :sessions

DB = Sequel.sqlite('database/comisspro.db')

unless DB.schema(:vendedores).any? { |c| c[0] == :ativo }
  DB.alter_table :vendedores do
    add_column :ativo, Integer, default: 1
  end
end

# Cria usuário admin caso não exista
if DB.table_exists?(:usuarios)
  DB[:usuarios].insert(
    nome: 'Administrador',
    email: 'admin@admin.com',
    senha: '123456',
    perfil: 'admin'
  ) if DB[:usuarios].count == 0
end

VENDEDORES = DB[:vendedores]
VENDAS = DB[:vendas]

set :bind, '127.0.0.1'
set :port, 4567

helpers do

  def moeda(valor)
    valor ||= 0

    "R$ #{sprintf('%.2f', valor)
      .gsub('.', ',')
      .reverse
      .gsub(/(\d{3})(?=\d)/, '\\1.')
      .reverse}"
  end

end

before do

  pass if request.path_info == '/login'

  redirect '/login' unless session[:usuario]

end

# ==========================
# LOGIN
# ==========================

get '/login' do
  erb :login
end

post '/login' do

  usuario = DB[:usuarios]
              .where(
                email: params[:email],
                senha: params[:senha]
              )
              .first

  if usuario

    session[:usuario] = usuario[:id]
    session[:perfil] = usuario[:perfil]

    redirect '/'

  else

    redirect '/login'

  end

end

# ==========================
# DASHBOARD
# ==========================

get '/' do

  @usuario = DB[:usuarios]
                .where(id: session[:usuario])
                .first

  @vendedores = VENDEDORES.all

@total_vendas =
  VENDAS.where(ativo: 1)
        .sum(:valor) || 0

@total_comissao =
  VENDAS.where(ativo: 1)
        .sum(:comissao) || 0

  mes = Time.now.month
  ano = Time.now.year

if DB.table_exists?(:metas)

  meta = DB[:metas]
            .where(mes: mes, ano: ano)
            .first

  @meta = meta ? meta[:valor] : 100000

else

  @meta = 100000

end


  @percentual_meta =
    ((@total_vendas.to_f / @meta.to_f) * 100).round(1)

  @percentual_meta = 100 if @percentual_meta > 100

  @filtro = params[:vendedor]

  query = "
    SELECT
      vendas.id,
      vendedores.nome,
      vendas.produto,
      vendas.valor,
      vendas.comissao,
      vendas.data,
      vendas.ativo
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
  "

  if @filtro && !@filtro.empty?
    query += " WHERE vendedores.nome LIKE '%#{@filtro}%' "
  end

  query += " ORDER BY vendas.id DESC LIMIT 20 "

  @historico = DB.fetch(query).all

    @ranking = DB.fetch("
    SELECT
      vendedores.nome,
      SUM(vendas.valor) total
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
    WHERE vendas.ativo = 1
    GROUP BY vendedores.nome
    ORDER BY total DESC
    LIMIT 5
  ").all

  quantidade =
    VENDAS.where(ativo: 1).count

  @ticket_medio =
    (@total_vendas / [quantidade, 1].max).round(2)

  @melhor_vendedor = DB.fetch("
    SELECT
      vendedores.nome,
      SUM(vendas.valor) total
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
    WHERE vendas.ativo = 1
    GROUP BY vendedores.nome
    ORDER BY total DESC
    LIMIT 1
  ").first

  erb :dashboard

end

get '/admin' do

  redirect '/' unless session[:perfil] == 'admin'

  @vendedores = VENDEDORES.order(:nome).all

  @vendas = DB.fetch("
    SELECT
      vendas.id,
      vendedores.nome,
      vendas.produto,
      vendas.valor,
      vendas.comissao,
      vendas.data
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
    WHERE vendas.ativo = 1
    ORDER BY vendas.id DESC
  ").all

  @meta = DB[:metas]
             .where(
               mes: Time.now.month,
               ano: Time.now.year
             )
             .first

  erb :admin
end
# ==========================
# VENDEDORES
# ==========================

post '/vendedor' do

  VENDEDORES.insert(
    nome: params[:nome],
    percentual: params[:percentual]
  )

  redirect '/'

end


post '/vendedor/excluir/:id' do

  redirect '/' unless session[:perfil] == 'admin'

  vendedor_id = params[:id].to_i

  possui_vendas =
    VENDAS.where(vendedor_id: vendedor_id)
          .count

  if possui_vendas > 0

    redirect '/admin'

  else

    VENDEDORES.where(id: vendedor_id)
              .delete

    redirect '/admin'

  end

end

# ==========================
# VENDAS
# ==========================

post '/venda' do

  vendedor_id = params[:vendedor_id].to_i
  produto = params[:produto]
  valor = params[:valor].to_f
  custo = params[:custo].to_f

  vendedor = VENDEDORES.where(id: vendedor_id).first

  percentual = vendedor[:percentual]

  comissao_bruta = valor * (percentual / 100.0)

  lucro = valor - custo

  comissao_liquida = lucro * (percentual / 100.0)

  VENDAS.insert(
    vendedor_id: vendedor_id,
    produto: produto,
    valor: valor,
    custo: custo,
    comissao: comissao_bruta,
    data: Time.now,
    ativo: 1
  )

  DB[:auditoria].insert(
    usuario: session[:usuario],
    acao: "Nova venda #{produto}",
    data: Time.now
  )

  redirect '/'

end

# ==========================
# METAS
# ==========================

post '/meta' do

  redirect '/' unless session[:perfil] == 'admin'

  atual = DB[:metas]
            .where(
              mes: Time.now.month,
              ano: Time.now.year
            )
            .first

  if atual

    DB[:metas]
      .where(id: atual[:id])
      .update(valor: params[:valor])

  else

    DB[:metas].insert(
      valor: params[:valor],
      mes: Time.now.month,
      ano: Time.now.year
    )

  end

  redirect '/admin'

end


# ==========================
# PRODUTOS
# ==========================

get '/produtos' do

  redirect '/' unless ['admin','gerente'].include?(session[:perfil])

  @produtos = DB[:produtos]
                .order(:nome)
                .all

  erb :produtos

end

post '/produto' do

  redirect '/' unless ['admin','gerente'].include?(session[:perfil])

  DB[:produtos].insert(
    nome: params[:nome],
    categoria: params[:categoria],
    custo_kg: params[:custo_kg],
    preco_kg: params[:preco_kg],
    estoque_kg: params[:estoque_kg],
    estoque_minimo: params[:estoque_minimo],
    ativo: 1
  )

  redirect '/produtos'

end
# ==========================
# RELATÓRIO POR PERÍODO
# ==========================

get '/relatorio' do

  inicio = params[:inicio]
  fim = params[:fim]

  @vendas = DB.fetch("
    SELECT
      vendedores.nome,
      vendas.valor,
      vendas.comissao,
      vendas.data
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
    WHERE date(vendas.data)
      BETWEEN '#{inicio}'
      AND '#{fim}'
  ").all

  erb :relatorio

end

# ==========================
# EXPORTAÇÃO XLSX
# ==========================

get '/exportar/xlsx' do

  vendas = DB.fetch("
    SELECT
      vendedores.nome,
      vendas.valor,
      vendas.comissao,
      vendas.data
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
  ").all

  ExcelExporter.generate(vendas)

  send_file(
    'relatorio_comissoes.xlsx',
    filename: 'relatorio_comissoes.xlsx',
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  )

end

# ==========================
# EXPORTAÇÃO PDF
# ==========================
=begin
get '/exportar/pdf' do

  vendas = DB.fetch("
    SELECT
      vendedores.nome,
      vendas.valor,
      vendas.comissao,
      vendas.data
    FROM vendas
    JOIN vendedores
      ON vendedores.id = vendas.vendedor_id
  ").all

  PdfExporter.generate(vendas)

  send_file(
    'relatorio_comissoes.pdf',
    filename: 'relatorio_comissoes.pdf',
    type: 'application/pdf'
  )

end
=end

post '/venda/excluir/:id' do

  redirect '/' unless session[:perfil] == 'admin'

VENDAS.where(id: params[:id]).update(
  ativo: 0
)

redirect '/admin'

end

post '/vendedor/percentual' do

  redirect '/' unless ['admin','gerente'].include?(session[:perfil])

  VENDEDORES
    .where(id: params[:id])
    .update(percentual: params[:percentual])

  redirect '/admin'

end

get '/vendedor/:id' do

  @vendedor =
    VENDEDORES.where(id: params[:id]).first

  @vendas = DB.fetch("
    SELECT *
    FROM vendas
    WHERE vendedor_id = ?
    AND ativo = 1
    ORDER BY data DESC
  ", params[:id]).all

  erb :vendedor_detalhe

end

get '/vendedor/:id/exportar' do

  vendas = DB.fetch("
    SELECT
      vendas.produto,
      vendas.valor,
      vendas.comissao,
      vendas.data
    FROM vendas
    WHERE vendedor_id = ?
    AND ativo = 1
  ", params[:id]).all

  ExcelExporter.generate(vendas)

  send_file(
    'relatorio_comissoes.xlsx'
  )

end

get '/usuarios' do

  redirect '/' unless session[:perfil] == 'admin'

  @usuarios = DB[:usuarios].all

  erb :usuarios

end

post '/usuario' do

  redirect '/' unless session[:perfil] == 'admin'

  DB[:usuarios].insert(
    nome: params[:nome],
    email: params[:email],
    senha: params[:senha],
    perfil: params[:perfil]
  )

  redirect '/usuarios'

end

post '/vendedor/desativar/:id' do

  redirect '/' unless session[:perfil] == 'admin'

  VENDEDORES
    .where(id: params[:id])
    .update(ativo: 0)

  redirect '/admin'

end

post '/vendedor/ativar/:id' do

  redirect '/' unless session[:perfil] == 'admin'

  VENDEDORES
    .where(id: params[:id])
    .update(ativo: 1)

  redirect '/admin'

end