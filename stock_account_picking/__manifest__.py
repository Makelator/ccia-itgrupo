# -*- encoding: utf-8 -*-
{
	'name': 'Crear factura de un alvaran',
	'category': 'stock',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['stock','account_invoice_nc_it'],
	'version': '1.0',
	'description':"""
	Crear factura al devolver un alvaran
	""",
	'auto_install': False,
	'demo': [],
	'data':	[
		'stock_invoice_onshipping_view.xml',
		'stock_return_picking_view.xml',
	],
	'installable': True
}
