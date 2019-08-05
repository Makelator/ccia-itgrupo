# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Modulo Socios Camara de Comercio',
    'version': '2.0',
    'category': '',
    'description': """

    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['account','creacion_product_service_res_p','agregar_campo_resp_estado_afiliacion_it'],
    'data': [
            'views/socios.xml'
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
}