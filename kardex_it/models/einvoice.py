# -*- coding: utf-8 -*-
from openerp import _, api, fields, models
from odoo.osv import expression
class einvoice_catalog_12(models.Model):
	_name = "einvoice.catalog.12"
	_description = 'Tipo de operacion'

	code = fields.Char(string='Codigo', size=4, index=True, required=True)
	name = fields.Char(string='Descripcion', size=128, index=True, required=True)
	
	@api.multi
	@api.depends('code', 'name')
	def name_get(self):
		result = []
		for table in self:
			l_name = table.code and table.code + ' - ' or ''
			l_name +=  table.name
			result.append((table.id, l_name ))
		return result

class einvoice_catalog_05(models.Model):
	_name = "einvoice.catalog.05"
	_description = 'Tipo de existencia'

	code = fields.Char(string='Codigo', size=4, index=True, required=True)
	name = fields.Char(string='Descripcion', size=128, index=True, required=True)
	
	@api.multi
	@api.depends('code', 'name')
	def name_get(self):
		result = []
		for table in self:
			l_name = table.code and table.code + ' - ' or ''
			l_name +=  table.name
			result.append((table.id, l_name ))
		return result

class einvoice_catalog_06(models.Model):
	_name = "einvoice.catalog.13"
	_description = 'codigo de unidad de medida'

	code = fields.Char(string='Codigo', size=4, index=True, required=True)
	name = fields.Char(string='Descripcion', size=128, index=True, required=True)
	
	@api.multi
	@api.depends('code', 'name')
	def name_get(self):
		result = []
		for table in self:
			l_name = table.code and table.code + ' - ' or ''
			l_name +=  table.name
			result.append((table.id, l_name ))
		return result