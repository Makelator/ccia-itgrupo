# -*- coding: utf-8 -*-
import openerp.addons.decimal_precision as dp
from openerp import models, fields
class make_kardex_tree(models.Model):
	_name = "make.kardex.tree"

	location_id=fields.Char('Ubicacion',size=250)
	producto=fields.Char('Producto',size=150)
	category_id=fields.Char('Categoria',size=150)
	date= fields.Date('Fecha')
	type_doc= fields.Char(size=20,string='Tipo')
	serial_doc= fields.Char(size=10,string='Serie')
	num_doc= fields.Char(size=24,string='Numero')
	type_ope= fields.Char(size=40,string='Tipo de operacion')
	partner_id= fields.Char('Razon social',size=150)
	input= fields.Float(string='Entradas',digits_compute=dp.get_precision('Account'))
	output= fields.Float(string='Salidas',digits_compute=dp.get_precision('Account'))
	saldo=fields.Float(string='Saldo final',digits_compute=dp.get_precision('Account'))
	period_id=fields.Char(string="Periodo",size=10)
	cadquiere=fields.Float(string='C. Adquisicion',digits_compute=dp.get_precision('Product Price'))
	debit=fields.Float(string='Debe',digits_compute=dp.get_precision('Account'))
	credit=fields.Float(string='Haber',digits_compute=dp.get_precision('Account'))
	saldoval=fields.Float(string='Saldo Valorado',digits_compute=dp.get_precision('Account'))
	cprom=fields.Float(string='C. Promedio',digits_compute=dp.get_precision('Product Price'))
	analitic_id=fields.Char(size=250,string='Cta. Analitica.')
	tipomove=fields.Char(size=2,string='Tipo de operacion')
	analitic_id2=fields.Many2one('account.analytic.account','Cta. Analitica')