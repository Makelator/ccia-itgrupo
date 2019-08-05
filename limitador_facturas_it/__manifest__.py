# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Limitador de Facturas por Cliente(Equipo Venta)',
    'version': '2.0',
    'category': '',
    'description': """
    Se limitan el numero de facuras que se le pueden hacer a un cliente de un grupo de ventas determinado utilizando una advertencia de si desea continuar
    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['account','account_parametros_it'],
    'data': [
            'wizards/wizard_account_invoice_confirmation.xml',
            'views/account_invoice_inherit.xml',
            'views/main_parameter_inherit.xml',
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
}