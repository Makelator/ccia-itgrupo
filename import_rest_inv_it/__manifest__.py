# -*- encoding: utf-8 -*-
{
	'name': 'Importar inventario inicial',
	'category': 'stock',
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'depends': ['stock','kardex_it'],
	'version': '1.0.0',
	'description':"""
	IMPORTA EL INVENTARIO INICIAL BASADO EN UN CSV CON LAS SIGUENTES COLUMNAS:
	id producto|referencia interna|cantidad|preciounitario
	""",
	'auto_install': False,
	'demo': [],
	'data':	['import_rest_inv_view.xml'],
	'installable': True
}
