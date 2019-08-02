# -*- encoding: utf-8 -*-
{
	'name': 'Precio UniTario Acces Stock Picking',
	'category': 'account',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['sales_team','purchase','stock','kardex_it','sales_team'],
	'version': '1.0',
	'description':"""
	Acceso Precio UniTario Acces Stock
	""",
	'auto_install': False,
	'demo': [],
	'data':	[
	'security/user_groups.xml',
    'security/ir.model.access.csv',
    'stock_picking_inherit.xml',

	],
	'installable': True
}