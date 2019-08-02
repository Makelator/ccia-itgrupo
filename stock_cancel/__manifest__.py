# -*- encoding: utf-8 -*-
##############################################################################
#
#    OpenERP, Open Source Management Solution
#    Copyright (c) 2012 Andrea Cometa All Rights Reserved.
#                       www.andreacometa.it
#                       openerp@andreacometa.it
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

{
	'name': 'Stock Cancel',
	'version': '1.2',
	'category': 'Stock',
	'description': """ENG: This module allows you to bring back a completed stock picking to draft state\nITA: Questo modulo consente di riaprire uno stock.picking completato
	""",
	'author': 'ITGRUPO-COMPATIBLE-BO',
	'website': 'http://www.andreacometa.it',
	'depends': ['stock','sale_stock'],
	'data': [
		'security/permisos.xml',
		'stock_view.xml',
		'security/ir.model.access.csv',
		],
	'installable': True,
	'active': False,
	'images' : ['images/stock_picking.jpg'],
	'ITGRUPO_VERSION':2,
}

