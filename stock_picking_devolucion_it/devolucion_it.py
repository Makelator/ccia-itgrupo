# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api , exceptions, _

class stock_picking(models.Model):
	_inherit = 'stock.picking'

	picking_origen_devolucion = fields.Many2one('stock.picking','Factura Origen de Devolución')

class StockReturnPicking(models.TransientModel):
	_inherit = "stock.return.picking"

	@api.multi
	def _create_returns(self):
		new_picking_id, pick_type_id = super(StockReturnPicking, self)._create_returns()
		stock_picking_origen = self.env['stock.picking'].browse(self.env.context['active_id'])
		stock_picking_nuevo = self.env['stock.picking'].browse(new_picking_id)
		stock_picking_nuevo.invoice_id = False
		stock_picking_nuevo.picking_origen_devolucion = stock_picking_origen.id
		return new_picking_id, pick_type_id



class stock_invoice_onshipping(models.TransientModel):
	_inherit = 'stock.invoice.onshipping'

	@api.multi
	def open_invoice(self):
		t = super(stock_invoice_onshipping,self).open_invoice()
		picking_actual = self.env['stock.picking'].browse(self.env.context['active_id'])
		picking_actual.invoice_id = t['res_id']

		if picking_actual.picking_origen_devolucion.id:
			factura = picking_actual.picking_origen_devolucion.invoice_id
			if factura.currency_id.name == 'USD':
				factura_dev = self.env['account.invoice'].browse(t['res_id'])
				factura_dev.check_currency_rate = True
				factura_dev.currency_rate_auto = factura.currency_rate_auto
			data  = {
				'igv': factura.amount_tax,
				'fecha': factura.date_invoice,
				'comprobante': factura.reference,
				'base_imponible': factura.amount_untaxed,
				'perception': factura.amount_total,
				'tipo_doc': factura.it_type_document.id,
				'father_invoice_id': t['res_id'],
			}
			self.env['account.perception'].create(data)
		return t