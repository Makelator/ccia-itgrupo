# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Funciones Adicionales a Cotizaciones y Eventos',
    'version': '2.0',
    'category': '',
    'description': """
    Se agregan funciones adcionales a las cotizaciones vinculandolas con eventos
    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['event','sale','sale_order_contact','account','creacion_product_service_res_p'],
    'data': [
            'views/sale_order_inherit.xml',
            'views/event_event_inherit.xml',   
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
}