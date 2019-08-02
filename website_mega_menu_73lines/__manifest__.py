# -*- coding: utf-8 -*-
# Part of Odoo Module Developed by 73lines
# See LICENSE file for full copyright and licensing details.

{
    'name': 'Website Mega Menu',
    'summary': 'Website Mega Menu',
    'description': 'Website Mega Menu',
    'category': 'Website',
    'version': '10.0.1.0.0',
    'author': '73Lines, ODOOPERU',
    'website': 'https://www.73lines.com/',
    'depends': ['website'],
    'data': [
        'views/assets.xml',
        'views/templates_submenu.xml',
        'views/website_views.xml'
    ],
    'images': [
        'static/description/website_mega_menu.jpg',    
    ],
    'installable': True,
    'price': 40,
    'license': 'OEEL-1',
    'currency': 'EUR',
}
