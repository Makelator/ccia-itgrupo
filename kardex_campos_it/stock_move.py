# -*- coding: utf-8 -*-
from openerp import _, api, fields, models
from odoo.osv import expression

class stock_move(models.Model):
	_inherit='stock.move'


	precio_unitario_manual = fields.Float(string='P.Unit')
