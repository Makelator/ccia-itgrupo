# -*- encoding: utf-8 -*-
{
	'name': 'Control de transferencias Internas',
	'category': 'base',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['import_base_it','stock','kardex_product_saldofisico_it','print_guia_remision_it'],
	'version': '1.0.0',
	'description':"""
	Agrega un campo que permite saber si el pedido esta en ruta o ya llego
	""",
	'auto_install': False,
	'demo': [],
	'data':	['views/internal_move_control_it.xml'],
	'installable': True
}
