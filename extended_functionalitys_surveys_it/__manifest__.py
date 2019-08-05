# -*- encoding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Extended Funcionalitys For Survey',
    'version': '2.0',
    'category': 'Marketing',
    'description': """
    Se agregan funcionalidades para poder imprimir el reporte y adjuntar archivos en un campo nuevo para las preguntas
    """,
    'author': "ITGRUPO-CCIA",
    'website': "http://www.itgrupo.net",
    'depends': ['survey'],
    'data': [

    ],
    'demo': ['survey_templates_inehrit.xml',
             'survey_result_inehrit.xml',
             'survey_input_line_form_inherit.xml'
             ],
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 105,
}
