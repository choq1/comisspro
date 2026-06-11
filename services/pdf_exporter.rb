require 'prawn'

class PdfExporter

  def self.generate(vendas)

    Prawn::Document.generate(
      "relatorio_comissoes.pdf"
    ) do

      text "RELATÓRIO DE COMISSÕES",
           size: 20,
           style: :bold

      move_down 20

      vendas.each do |v|

        text "#{v[:data]} | #{v[:nome]} | Venda: R$ #{v[:valor]} | Comissão: R$ #{v[:comissao]}"

      end

    end

  end

end