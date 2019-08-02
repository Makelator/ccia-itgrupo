# -*- encoding: utf-8 -*-
{
	'name': 'Aprobacion de devolucion',
	'category': 'account',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['print_guia_remision_it'],
	'version': '1.0',
	'description':"""
	Aprobacion de devolucion a proveedor
	""",
	'auto_install': False,
	'demo': [],
	'data':	[
		'security/permisos.xml',
		'stock_picking_view.xml',
	],
	'installable': True
}
