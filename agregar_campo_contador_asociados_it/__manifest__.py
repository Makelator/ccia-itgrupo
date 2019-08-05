# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Campo asociados_count contador para res_partner',
    'version': '2.0',
    'category': '',
    'description': """

    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['account','relacion_estados_asociados_it','agregar_booleano_confirmacion_estado_partner_it','agregar_campo_resp_estado_afiliacion_it','socios_ccis_it'],
    'data': [
            #'wizard/socio_confirmation.xml',
            'res_partner.xml'   
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': True,
}