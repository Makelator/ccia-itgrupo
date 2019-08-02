# -*- encoding: utf-8 -*-
{
	'name': 'Impresion de guia de remision',
	'category': 'account',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['account','stock'],
	'version': '1.0',
	'description':"""
	Imprime guia en remision en caso de que la orden de entrega sea para un cliente
	""",
	'auto_install': False,
	'demo': [],
	'data':	[
	'stock_picking_view.xml'
	],
	'installable': True
}
