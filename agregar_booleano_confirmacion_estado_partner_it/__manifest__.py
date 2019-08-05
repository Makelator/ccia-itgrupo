# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Campo confirmacion_estado para res_partner',
    'version': '2.0',
    'category': '',
    'description': """

    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['account','relacion_estados_asociados_it'],
    'data': [
            'security/user_groups.xml',
            'res_partner.xml',
                ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
}