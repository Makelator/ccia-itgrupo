# -*- encoding: utf-8 -*-
{
	'name': 'Costo de Ventas Asiento IT',
	'category': 'account',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['import_base_it','kardex_it'],
	'version': '1.0',
	'description':"""
	Creacion de Asiento de Costo de Ventas
	""",
	'auto_install': False,
	'demo': [],
	'data':	['wizard/account_analytic_book_major_wizard_view.xml','account_analytic_book_major_view.xml'],
	'installable': True
}
