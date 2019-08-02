# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api , exceptions, _
from openerp.exceptions import  Warning

class stock_warehouse(models.Model):
	_inherit = 'stock.warehouse'

	
	
	it_type_document = fields.Many2one('einvoice.catalog.01','Tipo de Documento',required=False)
	serie_id = fields.Many2one('it.invoice.serie', string="Serie",index=True)
