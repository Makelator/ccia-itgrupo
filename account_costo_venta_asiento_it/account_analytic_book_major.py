# -*- coding: utf-8 -*-

from openerp import models, fields, api


class view_costo_venta_it(models.Model):
	_name = 'view.costo.venta.it'
	_auto = False

	period_id = fields.Many2one('account.period','Periodo')
	almacen = fields.Many2one('stock.location','Almacen')
	producto = fields.Many2one('product.product','Producto')
	salidas = fields.Float('Salidas')
	devoluciones = fields.Float('Devoluciones')
	costo_ventas = fields.Float('Costo de Ventas')
	cuenta_salida = fields.Many2one('account.account','Cuenta Salida',related="producto.categ_id.property_stock_account_output_categ_id")
	cuenta_valuacion = fields.Many2one('account.account','Cuenta Valuacion',related="producto.categ_id.property_stock_valuation_account_id")