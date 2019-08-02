# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api , exceptions, _
from openerp.exceptions import  Warning

class sale_order(models.Model):
	_inherit = "sale.order"

	@api.multi
	def _prepare_invoice(self):
		invoice_vals = super(sale_order,self)._prepare_invoice()
		if self.warehouse_id.serie_id:
			next_number = self.warehouse_id.serie_id.sequence_id.number_next_actual
			if self.warehouse_id.serie_id.sequence_id.prefix == False:
				raise osv.except_osv('Alerta!', "No existe un prefijo configurado en la secuencia de la serie.")
			prefix = self.warehouse_id.serie_id.sequence_id.prefix
			padding = self.warehouse_id.serie_id.sequence_id.padding
			nro = prefix + "0"*(padding - len(str(next_number))) + str(next_number)
			invoice_vals.update({'reference': nro})
			invoice_vals.update({'it_type_document': self.warehouse_id.it_type_document.id})
			invoice_vals.update({'serie_id':self.warehouse_id.serie_id.id})
		return invoice_vals