require 'caxlsx'

class ExcelExporter

  def self.generate(vendas)

    package = Axlsx::Package.new

    workbook = package.workbook

    workbook.add_worksheet(name: "Comissões") do |sheet|

      sheet.add_row [
        "Data",
        "Vendedor",
        "Venda",
        "Comissão"
      ]

      vendas.each do |v|
        sheet.add_row [
          v[:data],
          v[:nome],
          v[:valor],
          v[:comissao]
        ]
      end

    end

    package.serialize("relatorio_comissoes.xlsx")

  end

end