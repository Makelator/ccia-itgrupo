# -*- coding: utf-8 -*-
import openerp.addons.decimal_precision as dp
from openerp import models, fields
class kardex_vs_account_line(models.Model):
	_name = "kardex.vs.account.line"

	
	cta=fields.Char(size=100,string="Cuenta")
	periodo=fields.Char(size=20,string="Periodo")
	proveedor=fields.Char(size=200,string="Proveedor")
	factura=fields.Char(size=20,string="Factura")
	producto=fields.Char(size=200,string="Producto")
	montokardex=fields.Float(digits=(20,2),string="Valor kardex")
	contable=fields.Float(digits=(20,2),string="Valor contable")
	dif=fields.Float(digits=(20,2),string="Diferencia")

	_order = "periodo,proveedor,factura,producto"