# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'MESA DE PARTES',
    'version': '2.0',
    'category': '',
    'description': """
    Modulo Base para Mesa de Partes
    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['mail'],
    'data': [
            'security/user_groups.xml',
            'security/ir.model.access.csv',
            'views/mesa_partes_views.xml',
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 105,
}
